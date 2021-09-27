# Automate VHD or VHDX creation from CBL-Mariner ISO image using ['packer']( https://www.packer.io/) (1)
This set of scripts and configuration files can be used to automate VHDX (2) creation and customization from an initial CBL-Mariner ISO image. These scripts are designed to run on Windows.
The ISO image can be local or fetched from a server. The ++original ISO image must contains 'openssh-server' packages++, because 'packer' relies on ssh to communicate with the VM once it has been programmatically configured and booted.


This tooling relies on two configuration files: 'packer' configuration [packer_config.json](https://github.com/microsoft/CBL-MarinerDemo/blob/nicogbg/image-from-packer/imaging-from-packer/packer_config.json) and CBL-Mariner image configuration [mariner_config.json](https://github.com/microsoft/CBL-MarinerDemo/blob/nicogbg/image-from-packer/imaging-from-packer/mariner_config.json) (aka unattended configuration) that are customized using a PowerShell script [Create-VM.ps1](https://github.com/microsoft/CBL-MarinerDemo/blob/nicogbg/image-from-packer/imaging-from-packer/Create-VM.ps1). This PowerShell script will also launch 'packer' to create the VHDX. Once the VM has boot and after its initial configuration has been applied 'packer' will use its provisionners (1) to launch customization scripts which can be use to install new packages.

![](PackerFlow.png)

###### Prerequisits
- enable Hyper-V feature on your Windows machine
- install 'packer' on your Windows machine

###### Notes
(1) For more information about 'packer' see https://www.packer.io/ and more specifically the [hyper-v builder](https://www.packer.io/docs/builders/hyperv/iso)
(2) VHD creation just requires to change 1 parameter in the 'packer' configuration file.
(3) This is available for **CBL-Mariner version 1.0.20210930 and above**

