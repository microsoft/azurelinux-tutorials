param (
   # path to the iso file (could be a URL)
   [string]
   $isoFile = "https://osrelease.download.prss.microsoft.com/pr/download/Mariner-1.0-x86_64.iso",

   # ISO file checksum, could be either:
   #   - URL like https://osrelease.download.prss.microsoft.com/pr/download/Mariner-1.0-x86_64.iso.sha256
   #   - text [checksum type]:[value], e.g.: sha256:246F000F1C493E5A8F78D13D4503DDB4BE5A77A5418A42809CC3CA5B8111931A
   [string]
   $isoChecksum = "https://osrelease.download.prss.microsoft.com/pr/download/Mariner-1.0-x86_64.iso.sha256",

   # Name of the CBL-Mariner configuration in the ISO
   # Note that default config name for CBL-Mariner ISO is "CBL-Mariner Full"
   [string]
   $marinerConfigName = 'CBL-Mariner Full',

   # username used to login
   [Parameter(mandatory=$true)]
   [ValidateNotNullorEmpty()]
   [string]
   $userName,

   # password use to login
   [Parameter(mandatory=$true)]
   [ValidateNotNullorEmpty()]
   [string]
   $password,
   
   # path to provisionner folder
   # Note that everything under that path will be copied to the VM
   [string]
   $srcProvisionerFolder = "$PSScriptRoot\provisioners",
   
   # name of the 'main' provisioner script
   # this script must be in the provisionner folder
   [string]
   $provisionerScript = 'customizeMariner.sh',
   
   # Name of the VM
   [string]
   $vmName = 'TestVM',

   # folder where VHDX will be copied
   [string]
   $outDir = "$PSScriptRoot\outdir",

   # Size of the VM/VHDX hard drive
   [string]
   $diskSize = '10240',

   # Number of CPU of the VM/VHDX
   [string]
   $cpu = '2',

   # Amount of RAM for VM/VHDX
   [string]
   $memory = '2048',

   # name of the Hyper-V virtual switch to use 
   [Parameter(mandatory=$true)]
   [ValidateNotNullorEmpty()]
   [string]
   $hyperVSwitchName
)

function Replace-InFile {
   param (
      $tagToReplace,
      $tagValue,
      $fileName
   )
   $tempName = (Get-ChildItem $fileName).Name
   Write-Host "$tempName -> replace $tagToReplace with $tagValue"
   (Get-Content $fileName) | %{$_ -replace $tagToReplace,$tagValue} | Set-Content $fileName
}

if (! (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) )
{
   Write-Host "Error: needs admin rights to run"
   exit 1
}

$tempFolder = Join-Path $Env:Temp $(New-Guid)
$packerHttpFolder = "$tempFolder\packer_http"
$tempOutDir=".\\outdir"
$tempProvisionerFolderName="provisioners"

$marinerUnattendedConfigFile = "mariner_config.json"
$marinerPostInstallScript = "postinstall.sh"
$packerConfigFile = "packer_config.json"

try 
{
   # create a brand new output directory
   if (Test-Path $outDir) { 
      Write-Host "-- Remove $outDir"
      Remove-Item $outDir -Recurse -Force -Confirm:$false
   }
   New-Item -Path $outDir -ItemType directory

   # creat working directories
   New-Item -Path $packerHttpFolder -ItemType directory

   if ($isoFile.Contains("https://")) {
      Write-Host "get iso from $isoFile"
      Invoke-WebRequest -Uri $isoFile -OutFile $tempFolder/MarinerImage.iso
      $isoFileName = MarinerImage.iso
   }
   else {
      # copy iso file to build dir (temp folder)
      Write-Host "Copy iso file to working directory"
      Copy-Item $isoFile -Destination $tempFolder -Force
      $isoFileName = (Get-ChildItem $isoFile).Name
   }

   # Get package list from atttended config file in the iso
   Write-Host "Get package lists from iso"
   Mount-DiskImage -ImagePath $tempFolder/$isoFileName
   $driveLetter=(Get-DiskImage -ImagePath $tempFolder/$isoFileName | Get-Volume).DriveLetter
   $attendedConfig=(Get-Childitem -Path "${driveLetter}:\*" -Include "ATTENDED_CONFIG.json" -Recurse).FullName
   if (! $attendedConfig) {
      Write-Host "Error: The iso contains an unattended config file and cannot be customized using packer"
      exit 1
   }

   $packageListFound = $false
   $packageLists = ""
   Write-Host "Get package list from $attendedConfig"
   $configJson = Get-Content $attendedConfig -Raw | ConvertFrom-Json
   ForEach ($systemConfig in $configJson.SystemConfigs) {
      if ($systemConfig.Name -eq $marinerConfigName) {
         Write-Host "Extract package list from '$marinerConfigName' config"
         $packageListFound = $true

         ForEach ($package in $systemConfig.PackageLists) {
            if ($packageLists.Length -ne 0) {
               $packageLists += ", "
            }
            $packageLists = $packageLists + '"' + $package + '"'
         }
         break
      }
   }

   if (!$packageListFound) {
      Write-Host "Error: config '$marinerConfigName' cannot be found in the iso"
      exit 1
   }

   # populate working dir
   Write-Output "Populate working folder ($tempFolder)"
   Copy-Item $PSScriptRoot\$packerConfigFile -Destination $tempFolder -Force
   Copy-Item $PSScriptRoot\$marinerUnattendedConfigFile -Destination $packerHttpFolder -Force
   Copy-Item $PSScriptRoot\$marinerPostInstallScript -Destination $packerHttpFolder -Force

   New-Item -Path $tempFolder\$tempProvisionerFolderName -ItemType directory
   Copy-Item $srcProvisionerFolder\* -Destination $tempFolder\$tempProvisionerFolderName -Force -Recurse

   # customized config files (packer and mariner)
   Replace-InFile -tagToReplace "@VMNAME@" `
                  -tagValue "$vmName" `
                  -fileName $tempFolder\$packerConfigFile
   Replace-InFile -tagToReplace "@NETWORKSWITCH@" `
                  -tagValue "$hyperVSwitchName" `
                  -fileName $tempFolder\$packerConfigFile
   Replace-InFile -tagToReplace "@USERNAME@" `
                  -tagValue "$userName" `
                  -fileName $tempFolder\$packerConfigFile
   Replace-InFile -tagToReplace "@PASSWORD@" `
                  -tagValue "$password" `
                  -fileName $tempFolder\$packerConfigFile
   Replace-InFile -tagToReplace "@ISOFILE@" `
                  -tagValue "$isoFileName" `
                  -fileName $tempFolder\$packerConfigFile
   Replace-InFile -tagToReplace "@ISOCHECKSUM@" `
                  -tagValue "$isoChecksum" `
                  -fileName $tempFolder\$packerConfigFile
   Replace-InFile -tagToReplace "@DISKSIZE@" `
                  -tagValue "$diskSize" `
                  -fileName $tempFolder\$packerConfigFile
   Replace-InFile -tagToReplace "@CPU@" `
                  -tagValue "$cpu" `
                  -fileName $tempFolder\$packerConfigFile
   Replace-InFile -tagToReplace "@MEMORY@" `
                  -tagValue "$memory" `
                  -fileName $tempFolder\$packerConfigFile
   Replace-InFile -tagToReplace "@OUTDIR@" `
                  -tagValue "$tempOutDir" `
                  -fileName $tempFolder\$packerConfigFile
   Replace-InFile -tagToReplace "@MARINERCONFIGFILE@" `
                  -tagValue "$marinerUnattendedConfigFile" `
                  -fileName $tempFolder\$packerConfigFile
   Replace-InFile -tagToReplace "@POSTINSTALLSCRIPT@" `
                  -tagValue "$marinerPostInstallScript" `
                  -fileName $tempFolder\$packerConfigFile
   Replace-InFile -tagToReplace "@PROVISIONERSCRIPT@" `
                  -tagValue "$provisionerScript" `
                  -fileName $tempFolder\$packerConfigFile
   Replace-InFile -tagToReplace "@PROVISIONERSRCFOLDER@" `
                  -tagValue "$tempProvisionerFolderName" `
                  -fileName $tempFolder\$packerConfigFile

   Replace-InFile -tagToReplace "@VMNAME@" `
                  -tagValue "$vmName" `
                  -fileName $packerHttpFolder\$marinerUnattendedConfigFile
   Replace-InFile -tagToReplace "@CONFIGNAME@" `
                  -tagValue "$marinerConfigName" `
                  -fileName $packerHttpFolder\$marinerUnattendedConfigFile
   Replace-InFile -tagToReplace '"@PACAKGELIST@"' `
                  -tagValue "$packageLists" `
                  -fileName $packerHttpFolder\$marinerUnattendedConfigFile
   Replace-InFile -tagToReplace "@USERNAME@" `
                  -tagValue "$userName" `
                  -fileName $packerHttpFolder\$marinerUnattendedConfigFile
   Replace-InFile -tagToReplace "@PASSWORD@" `
                  -tagValue "$password" `
                  -fileName $packerHttpFolder\$marinerUnattendedConfigFile
   Replace-InFile -tagToReplace "@POSTINSTALLSCRIPT@" `
                  -tagValue "$marinerPostInstallScript" `
                  -fileName $packerHttpFolder\$marinerUnattendedConfigFile

   # launch packer
   #
   # notes:
   #  - packer executable must be in system PATH
   #  - packer must be launched from location of its config file
   #    because config file uses relative path
   #  - last <wait> in the 'boot_command' is used to leave time
   #    to Mariner to setup, reboot and start sshd service
   #    before packer starts to poke ssh connection and overload it
   #  - launch with '-debug' option to debug

   Push-Location $tempFolder
   Write-Output 'Launch packer'
   packer build .\$packerConfigFile
   if (Test-Path $tempOutDir) 
   { 
      Copy-Item -Path $tempOutDir\* -Destination $outDir -Recurse
   }
   Pop-Location

}
finally  
{
   Write-Host "`n=========================="
   Write-Host "== Cleanup test machine =="
   Write-Host "=========================="

   Write-Host "-- dismount iso ($tempFolder/$isoFileName)"
   Dismount-DiskImage -ImagePath $tempFolder/$isoFileName

   Pop-Location
   if (Test-Path $tempFolder) 
   { 
      Write-Host "-- Remove $tempFolder"-
      Remove-Item $tempFolder -Recurse -Force -Confirm:$false
   }
}

