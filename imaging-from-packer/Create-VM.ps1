param (
   [string]
   $isoFile = "https://osrelease.download.prss.microsoft.com/pr/download/Mariner-1.0-x86_64.iso",
   # $isoFile = "$PSScriptRoot\full-1.0.20210922.iso",

   # checksum is stored here https://osrelease.download.prss.microsoft.com/pr/download/Mariner-1.0-x86_64.iso.sha256
   [string]
   $isoChecksum = "sha256:3dd44b3947829750bdd3164d4263df06867e49e421ed332d9c0dd54c12458092",
   # $isoChecksum = 'sha256:6A071F41773D2D2AFBB692C69DA82A9059D7CF9C6C8A8F7E9690036E5D4B0727',

   [string]
   $userName = 'mariner_user',

   [string]
   $password = 'Mariner@Test9',
   
   [string]
   $vmName = 'TestVM',

   [string]
   $outDir = "$PSScriptRoot\outdir",

   [string]
   $diskSize = '10240',

   [string]
   $cpu = '2',

   [string]
   $memory = '2048'
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

$networkSwitchName = "New Virtual Switch"
$marinerUnattendedConfigFile = "unattended_config.json"
$packerConfigFile = "mariner.json"

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

   if (! $isoFile.Contains("https://")) {
      # copy iso file to build dir (temp folder)
      Write-Host "Copy iso file to working directory"
      Copy-Item $isoFile -Destination $tempFolder -Force
      $isoFileName = (Get-ChildItem $isoFile).Name
   }
   else {
      Write-Host "Packer will download iso from $isoFile"
      $isoFileName = $isoFile
   }

   # populate working dir
   Write-Output "Populate working folder ($tempFolder)"
   Copy-Item $PSScriptRoot\$packerConfigFile -Destination $tempFolder -Force
   Copy-Item $PSScriptRoot\$marinerUnattendedConfigFile -Destination $packerHttpFolder -Force
   Copy-Item "$PSScriptRoot\postinstall.sh" -Destination $packerHttpFolder -Force

   # !!! DEBUG  ------------------------------------------------
   Copy-Item "$PSScriptRoot\test_installer.sh" -Destination $packerHttpFolder -Force
   # !!! DEBUG  ------------------------------------------------

   # customized config files (packer and mariner unattended)
   Replace-InFile -tagToReplace "@VMNAME@" `
                  -tagValue "$vmName" `
                  -fileName $tempFolder\$packerConfigFile
   Replace-InFile -tagToReplace "@NETWORKSWITCH@" `
                  -tagValue "$networkSwitchName" `
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

   Replace-InFile -tagToReplace "@VMNAME@" `
                  -tagValue "$vmName" `
                  -fileName $packerHttpFolder\$marinerUnattendedConfigFile
   Replace-InFile -tagToReplace "@USERNAME@" `
                  -tagValue "$userName" `
                  -fileName $packerHttpFolder\$marinerUnattendedConfigFile
   Replace-InFile -tagToReplace "@PASSWORD@" `
                  -tagValue "$password" `
                  -fileName $packerHttpFolder\$marinerUnattendedConfigFile

   # packer must be launched from location of its config file
   # because config file uses relative path
   Push-Location $tempFolder
   Write-Output 'Launch packer'
   packer build -debug .\$packerConfigFile
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

   Pop-Location
   if (Test-Path $tempFolder) 
   { 
      Write-Host "-- Remove $tempFolder"-
      Remove-Item $tempFolder -Recurse -Force -Confirm:$false
   }
}

