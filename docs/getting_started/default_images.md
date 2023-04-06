# Building

- [Tutorial: Build a Default VHD or VHDX](#tutorial-build-a-default-vhd-or-vhdx)
  - [Build VHD or VHDX](#build-vhd-or-vhdx)
  - [Use Hyper-V to Boot Your Image](#use-hyper-v-to-boot-your-image)
- [Tutorial: Build the default ISO](#tutorial-build-the-default-iso)

## Tutorial: Build a Default VHD or VHDX

The toolkit ships with several image configurations. These can be build using the tools outside the core repo.

### Build VHD or VHDX

Choose an image to build by invoking one of the following build commands from the _CBL-MarinerTutorials/toolkit_ folder.

```bash
# VHDX
sudo make image CONFIG_FILE=./imageconfigs/core-efi.json 
# VHD
sudo make image CONFIG_FILE=./imageconfigs/core-legacy.json
```

The first time make image is invoked the toolkit downloads the necessary toolchain packages from the CBL-Mariner repository at packages.microsoft.com.  These toolchain packages are the standard set needed to build any local packages contained in the CBL-MarinerTutorials repo.  Once the toolchain is ready, make automatically proceeds to build any local packages.  In this case, the core repo's image configs do not use any of the packages located in the Tutoria repo so nothing will be built. Make will then assemble the packages gathered from the package server to build an image.
The resulting images are placed in the CBL-MarinerTutorials/out folder

> VHDX:       `CBL-MarinerTutorials/out/images/core-efi/`
> VHD:        `CBL-MarinerTutorials/out/images/core-legacy/`

### Use Hyper-V to Boot Your Image

Copy your demo VHD or VHDX image to your Windows Machine and boot it with Hyper-V.

**Create VHD(X) Virtual Machine with Hyper-V**

1. From Hyper-V Select _Action->New->Virtual Machine_.
1. Provide a name for your VM and press _Next >_.
1. For VHD select `Generation 1`. For VHDX select `Generation 2`, then press _Next >_.
1. Change Memory size if desired, then press _Next >_.
1. Select a virtual switch, then press _Next >_.
1. Select Use an existing virtual hard disk, then browse and select your VHD(X) file.
1. Press _Finish_.

**[Gen2/VHDX Only] Fix Boot Options**

1. Right click your virtual machine from Hyper-V Manager
1. Select _Settings..._
1. Select Security and under _Template:_ select _Microsoft UEFI Certificate Authority_.

**Disable Secure Boot**

_Note:_ If you followed any of the previous tutorials in [Working with packages](docs/packages/working_with_packages.md), the kernel is no longer signed and secure boot must be disabled in order to boot your VHD(X) image.

1. Right click your virtual machine from Hyper-V Manager
1. Select _Settings..._
1. Select Security and uncheck the "Enable Secure Boot" box

**Boot and Sign-In to Your VHD(X) Image**

1. Right click your VM and select _Connect..._.
1. Select _Start_.
1. Wait for CBL-Mariner to boot to the login prompt, then sign in with:

```bash
    root
    p@ssw0rd
```

## Tutorial: Build the Default ISO

In the previous tutorial, we learned how to create a simple VHD(X) image. In this tutorial, we will turn our attention to creating a bootable ISO image for installing CBL-Mariner to either a physical machine or virtual hard drive.

Let's jump right in.  Run the following command to build a demo ISO:

```bash
cd CBL-MarinerTutorials/toolkit
sudo make iso CONFIG_FILE=../imageconfigs/demo_iso.json
```

**Copy ISO Image to Your VM Host Machine**

Copy your binary image(s) to your VM Host Machine using your preferred technique.

**Create VHD(X) Virtual Machine with Hyper-V**

1. From Hyper-V Select _Action->New->Virtual Machine_.
1. Provide a name for your VM and press _Next >_.
1. Select _Generation 1_ (VHD) or _Generation 2_ (VHDX), then press _Next >_.
1. Change Memory size if desired, then press _Next >_.
1. Select a virtual switch, then press _Next >_.
1. Select _Create a virtual hard disk_, choose a location for your VHD(X) and set your desired disk Size.  Then press _Next >_.
1. Select _Install an operating system from a bootable image file_ and browse to your demo ISO. 
1. Press _Finish_.

**[Gen2/VHDX Only] Fix Boot Options**

1. Right click your virtual machine from Hyper-V Manager
1. Select _Settings..._
1. Select Security and under _Template:_ select _Microsoft UEFI Certificate Authority_.
1. Select Firmware and adjust the boot order so DVD is first and Hard Drive is second.
1. Select _Apply_ to apply all changes.

**Disable Secure Boot**

_Note:_ If you followed any of the previous tutorials in [Working with packages](docs/packages/working_with_packages.md), the kernel is no longer signed and secure boot must be disabled in order to boot your VHD(X) image.

1. Right click your virtual machine from Hyper-V Manager
1. Select _Settings..._
1. Select Security and uncheck the "Enable Secure Boot" box

**Boot ISO**

1. Right click your VM and select _Connect..._.
1. Select _Start_.
1. Follow the Installer Prompts to Install your image
1. When installation completes, select restart to reboot the machine. The installation ISO will be automatically ejected.
1. When prompted sign in to your CBL-Mariner system using the user name and password provisioned through the Installer.