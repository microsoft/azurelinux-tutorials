# Building

> **Note:** For customizing Azure Linux images, we recommend using the [Prism tool](https://github.com/microsoft/azure-linux-image-tools), which is the preferred method for building custom images. Please refer to the [Prism Image Customizer documentation](https://microsoft.github.io/azure-linux-image-tools/imagecustomizer/README.html) for details. The instructions below are still valid but represent the legacy approach for building custom images.

- [Tutorial: Build the default ISO](#tutorial-build-the-default-iso)
  - [Build ISO](#build-iso)
  - [Use Hyper-V to Boot Your ISO Installer](#use-hyper-v-to-boot-your-iso-installer)
- [Tutorial: Build a Default VHD or VHDX](#tutorial-build-a-default-vhd-or-vhdx)
  - [Build VHD or VHDX](#build-vhd-or-vhdx)
  - [Use Hyper-V to Boot Your Image](#use-hyper-v-to-boot-your-image)

## Tutorial: Build the Default ISO

In this tutorial, we will create a bootable ISO image for installing Azure Linux to either a physical machine or virtual hard drive.

The toolkit ships with several image configurations. The [image config files](https://github.com/microsoft/azurelinux/blob/-/toolkit/docs/formats/imageconfig.md) define how an Azure Linux image is laid out once built or installed.  Each image config will also include a list of packages to install.

### Build ISO

Build the default ISO by invoking the following build command from the _azurelinux-tutorials/toolkit_ folder.

```bash
sudo make iso -j20 CONFIG_FILE=./imageconfigs/full.json
```

The first time `make image` is invoked, the toolkit downloads the necessary toolchain packages from the Azure Linux package repo at [packages.microsoft.com](packages.microsoft.com).  These toolchain packages are the standard set needed to build any local packages.  Once the toolchain is ready, `make` automatically proceeds to build any local packages.  In this case, the core repo's image configs do not use any of the packages located in the Tutorial repo so nothing will be built. `make` will then assemble the packages gathered from the package server to build the specified image.

The resulting ISO is placed in the `azurelinux-tutorials/out/images/full` folder.

### Use Hyper-V to Boot Your ISO Installer

See [Use Hyper-V to Boot Your ISO Installer](boot.md#use-hyper-v-to-boot-your-iso-installer) for instructions on using Hyper-V to boot the ISO.

## Tutorial: Build a Default VHD or VHDX

The tools can also create offline images that can be directly booted.

### Build VHD or VHDX

The tools can also build offline images for direct use in VMs or as containers:

```bash
# VHDX
sudo make image -j20 CONFIG_FILE=./imageconfigs/core-efi.json 
# VHD
sudo make image -j20 CONFIG_FILE=./imageconfigs/core-legacy.json
```

The resulting images are placed in the `azurelinux-tutorials/out` folder:

> VHDX:       `azurelinux-tutorials/out/images/core-efi/`
> VHD:        `azurelinux-tutorials/out/images/core-legacy/`

### Build the cloud-init configuration image

No user account is provisioned by default.  To sign-in to these images at runtime, the sample meta-user-data.iso image must also be built and installed in your VM's CD drive.  The cloud-init service will detect the ISO and provision a user account and password or SSH Key.

Before you can build the meta-user-data.iso image you will need to customize the user-data configuration file. From the toolkit folder, the file can be found in ./resources/assets/meta-user-data/user-data.  Using an editor set a username and password or SSH Key. After applying your edits generate the meta-user-data.iso file as follows:

```Bash
# Build the cloud-init configuration image
# The output image is ../out/images/meta-user-data.iso
sudo make -j20 meta-user-data
```

### Use Hyper-V to Boot Your Image

See [Use Hyper-V to Boot Your Offline Image](boot.md#use-hyper-v-to-boot-your-offline-image) for instructions on using Hyper-V to boot the image and add a user profile with the `meta-user-data.iso` file.
