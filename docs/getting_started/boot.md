# Booting

- [Use Hyper-V to Boot Your ISO Installer](#use-hyper-v-to-boot-your-iso-installer)
- [Use Hyper-V to Boot Your Offline Image](#use-hyper-v-to-boot-your-offline-image)

The following guide walks through booting images and ISOs on Windows using Hyper-V.

## Use Hyper-V to Boot Your ISO Installer

### Copy ISO Image to Your VM Host Machine

Copy your binary image(s) to your VM Host Machine using your preferred technique.

### Create VHD(X) Virtual Machine with Hyper-V

1. From Hyper-V Select _Action->New->Virtual Machine_.
1. Provide a name for your VM and press _Next >_.
1. Select _Generation 1_ (VHD) or _Generation 2_ (VHDX), then press _Next >_.
1. Change Memory size if desired, then press _Next >_.
1. Select a virtual switch, then press _Next >_.
1. Select _Create a virtual hard disk_, choose a location for your VHD(X) and set your desired disk Size.  Then press _Next >_.
1. Select _Install an operating system from a bootable image file_ and browse to your demo ISO.
1. Press _Finish_.

### [Gen2/VHDX Only] Fix Boot Options

1. Right click your virtual machine from Hyper-V Manager
1. Select _Settings..._
1. Select Security and under _Template:_ select _Microsoft UEFI Certificate Authority_.
1. Select Firmware and adjust the boot order so DVD is first and Hard Drive is second.
1. Select _Apply_ to apply all changes.

### Disable Secure Boot

_Note:_ If you followed any of the previous tutorials in [Working with packages](/docs/packages/working_with_packages.md), the kernel is no longer signed and secure boot must be disabled in order to boot your VHD(X) image.

1. Right click your virtual machine from Hyper-V Manager
1. Select _Settings..._
1. Select Security and uncheck the "Enable Secure Boot" box

### Disable Dynamic Memory**

_Note:_ Having Dynamic Memory enabled may lead your app to crash due to integration with the Hyper-V Memory Ballooning driver. To avoid this, dynamic memory must be disabled.

1. Right click your virtual machine from Hyper-V Manager
1. Select _Settings..._
1. Select Memory and uncheck the "Enable Dynamic Memory" box

### Boot ISO

1. Right click your VM and select _Connect..._.
1. Select _Start_.
1. Follow the Installer Prompts to Install your image
1. When installation completes, select restart to reboot the machine. The installation ISO will be automatically ejected.
1. When prompted sign in to your CBL-Mariner system using the user name and password provisioned through the Installer.

## Use Hyper-V to Boot Your Offline Image

Copy your demo VHD or VHDX image to your Windows Machine and boot it with Hyper-V.

### Create VHD(X) Virtual Machine with Hyper-V

1. From Hyper-V Select _Action->New->Virtual Machine_.
1. Provide a name for your VM and press _Next >_.
1. For VHD select `Generation 1`. For VHDX select `Generation 2`, then press _Next >_.
1. Change Memory size if desired, then press _Next >_.
1. Select a virtual switch, then press _Next >_.
1. Select Use an existing virtual hard disk, then browse and select your VHD(X) file.
1. Press _Finish_.

### [Gen2/VHDX Only] Fix Boot Options

1. Right click your virtual machine from Hyper-V Manager
1. Select _Settings..._
1. Select Security and under _Template:_ select _Microsoft UEFI Certificate Authority_.

### Disable Secure Boot

_Note:_ If you followed any of the previous tutorials in [Working with packages](/docs/packages/working_with_packages.md), the kernel is no longer signed and secure boot must be disabled in order to boot your VHD(X) image.

1. Right click your virtual machine from Hyper-V Manager
1. Select _Settings..._
1. Select Security and uncheck the "Enable Secure Boot" box

### Disable Dynamic Memory**

_Note:_ Having Dynamic Memory enabled may lead your app to crash due to integration with the Hyper-V Memory Ballooning driver. To avoid this, dynamic memory must be disabled.

1. Right click your virtual machine from Hyper-V Manager
1. Select _Settings..._
1. Select Memory and uncheck the "Enable Dynamic Memory" box

### [Images Without Pre-Set Users Only] Build and Mount the Meta-User-Data.Iso Image

_Note:_ If you followed any of the previous tutorials to build custom images in [Working with packages](/docs/packages/working_with_packages.md), your image will have a user provisioned. This step is only needed if you are booting an image **without a pre-defined user**.

1. Build `the meta-user.iso` file via the [instructions for using the meta-user.iso cloud init image](/docs/getting_started/default_images.md#build-the-cloud-init-configuration-image)
1. Right click your virtual machine from Hyper-V Manager
1. Select _Settings..._.
choose DVD Drive and press Add.
1. Select the _DVD Drive_. For Gen1/VHD Images, this is nested under _IDE Controller 1_. For Gen2/VHDX Images, this is nested under _SCSI Controller_.
1. Select _Image File:_ and browse to the meta-user-data.iso file.
1. Select _Apply_ to apply all changes.

### Boot and Sign-In to Your VHD(X) Image

1. Right click your VM and select _Connect..._.
1. Select _Start_.
1. Wait for CBL-Mariner to boot to the login prompt, then sign in with:
   - Default Images using `meta-user.iso`:

    ```bash
    mariner_user
    p@ssword
    ```

   - Custom Images Tutorial:

    ```bash
    root
    p@ssw0rd
    ```
