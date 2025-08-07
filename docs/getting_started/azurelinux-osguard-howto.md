# Booting Azure Linux OS Guard in your own Azure VM

## What is Azure Linux OS Guard?
Azure Linux OS Guard is a security initiative designed to enhance the integrity and trustworthiness of Linux hosts across Microsoft and our customers. It looks to bring capabilities such as code integrity, immutability, and access control to Linux hosts via Azure Linux. 

## Benefits of Azure Linux OS Guard

Azure Linux OS Guard offers several key benefits:

1. **Code Integrity**: By enforcing code integrity (CI) via Integrity Policy Enforcement (IPE) Azure Linux OS Guard ensures only trusted binaries (on the host and in containers) are loaded into memory. This further extends the security promise of Secure Boot (aka Trusted Launch) that ensures the integrity of the system is maintained during boot.
2. **Immutable /usr**: By ensuring `/usr` is read-only, the integrity of the core executables on the system can be maintained.  
3. **Declarative Image Builds & Servicing**: Azure Linux OS Guard makes heavy use of [Image Customizer](https://github.com/microsoft/azure-linux-image-tools) which is an image build solution built by the Core OS group within Microsoft, allowing users to easily extend the base image using a declarative configuration. 
4. **Mandatory Access Control**: Azure Linux OS Guard introduces SELinux in enforcing mode to ensure only authorized processes can perform certain actions. 

## Prerequisites

1. Install [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).
2. Install [ORAS](https://oras.land/docs/installation/). 

## Set up environment variables

Before starting, set up the following environment variables to customize your deployment. You can modify the values for the variables as you desire. **Note**: The `GALLERY_NAME` is unique per subscription, so you may want to change this:

```bash
# Set your Azure subscription ID
export SUBSCRIPTION_ID="<your-subscription-id>"

# Set resource configuration
export RESOURCE_GROUP_NAME="osguard-dev"
export LOCATION="southcentralus"
export STORAGE_ACCOUNT_NAME="osguardstorage"
export STORAGE_CONTAINER_NAME="vhd"

# Set gallery configuration
export GALLERY_NAME="osguardtest"
export GALLERY_IMAGE_DEFINITION="osguarddev"
export VM_NAME="osguard-vm"
export ADMIN_USERNAME="osguard-user"
```

**Note**: Make sure to replace `<your-subscription-id>` with your actual Azure subscription ID.

## Pull the latest VM Image and upload it to your own Azure Compute Gallery 

1) The Azure Linux OS Guard base image is available in Microsoft Artifact Registry. We will start with that as the base image. 

**Note**: this will pull the `image.vhd` and the `secure-boot.pem` that will be used in this tutorial. 

```bash
oras pull mcr.microsoft.com/azurelinux/3.0/image/linuxguard:3.0.20250702
```

2) Create a resource group.

```bash
az group create -n "$RESOURCE_GROUP_NAME" -l "$LOCATION"
```

3) Create a storage account and a container within it. 

```bash
az storage account create --resource-group "$RESOURCE_GROUP_NAME" --name "$STORAGE_ACCOUNT_NAME" --location "$LOCATION"
az storage container create --account-name "$STORAGE_ACCOUNT_NAME" --auth-mode login --name "$STORAGE_CONTAINER_NAME"
```

4) Upload the Azure Linux OS Guard VHD.

```bash
az storage blob upload --account-name "$STORAGE_ACCOUNT_NAME" --container-name "$STORAGE_CONTAINER_NAME" --name image.vhd --file image.vhd --auth-mode login
```

5) Create a compute gallery and an image definition in that gallery.

```bash
az sig create --resource-group "$RESOURCE_GROUP_NAME" --gallery-name "$GALLERY_NAME"
az sig image-definition create --resource-group "$RESOURCE_GROUP_NAME" --gallery-name "$GALLERY_NAME" --gallery-image-definition "$GALLERY_IMAGE_DEFINITION" --publisher lgpublisher --offer lgoffer --sku lgsku --os-type linux --os-state Generalized --hyper-v-generation V2 --features "DiskControllerTypes=SCSI,NVMe SecurityType=TrustedLaunchSupported"
```

6) Create a file named `deployment.bicep` and paste the below Bicep template. This will allow us to upload the custom keys used to sign the base images. In future releases, the Azure Linux team will sign the images with a Microsoft key. 

```yaml
param galleryName string
param imageDefinitionName string
param versionName string
param location string = resourceGroup().location
param regions array = [resourceGroup().location]
param sourceDiskId string
param sourceDiskUrl string
param defaultReplicaCount int = 1
param excludedFromLatest bool = false
param allowDeletionOfReplicatedLocations bool = false
param certificateBase64 string
param replicationMode string = 'Shallow'
resource imageVersion 'Microsoft.Compute/galleries/images/versions@2024-03-03' = {
  name: '${galleryName}/${imageDefinitionName}/${versionName}'
  location: location
  properties: {
    publishingProfile: {
      replicaCount: defaultReplicaCount
      targetRegions: [
        for region in regions: {
          name: region
          regionalReplicaCount: defaultReplicaCount
          storageAccountType: 'Standard_LRS'
        }
      ]
      excludeFromLatest: excludedFromLatest
      replicationMode: replicationMode
    }
    storageProfile: {
      osDiskImage: {
        hostCaching: 'ReadWrite'
        source: {
          id: sourceDiskId
          uri: sourceDiskUrl
        }
      }
    }
    safetyProfile: {
      allowDeletionOfReplicatedLocations: allowDeletionOfReplicatedLocations
    }
    securityProfile: {
      uefiSettings: {
        signatureTemplateNames: [
          'MicrosoftUefiCertificateAuthorityTemplate'
        ]
        additionalSignatures: {
          db: [
            {
              type: 'x509'
              value: [certificateBase64]
            }
          ]
          dbx: [
            {
              type: 'sha256'
              value: [
                'gLTZaTG/DQL9kaYeGdFPHaRS5m2yQIyoYE1BH5Jlnwo='
              ]
            }
          ]
        }
      }
    }
  }
  tags: {}
}
```

7) Deploy the Bicep template. **Note**: The `secure-boot.pem` file passed should be the path to the certificate pulled with ORAS in step #1. 

```bash 
az deployment group create \
  --name "image-version-deployment" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --template-file "deployment.bicep" \
  --parameters galleryName="$GALLERY_NAME" \
               imageDefinitionName="$GALLERY_IMAGE_DEFINITION" \
               versionName="0.0.1" \
               regions="[\"$LOCATION\"]" \
               sourceDiskId="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME" \
               sourceDiskUrl="https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/$STORAGE_CONTAINER_NAME/image.vhd" \
               certificateBase64="$(sed '0,/-----BEGIN CERTIFICATE-----/d;/-----END CERTIFICATE-----/d' "secure-boot.pem" | tr -d "\n")"
```

## Deploy a VM with the Azure Linux OS Guard VM

Run the following command to deploy a VM with the image you created. **Note**: There is a known issue with the Linux Guard image booting on smaller SKUs (such as Standard_DS1_v2).

```bash
az vm create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name "$VM_NAME" \
  --image "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Compute/galleries/$GALLERY_NAME/images/$GALLERY_IMAGE_DEFINITION/versions/latest" \
  --admin-username "$ADMIN_USERNAME" \
  --generate-ssh-keys \
  --security-type TrustedLaunch \
  --enable-secure-boot true \
  --enable-vtpm true \
  --size Standard_D2s_v5
```

## Clean up your resources

```bash
az group delete -n "$RESOURCE_GROUP_NAME"
```