# Building

- [Tutorial: Build a Default VHD or VHDX](#tutorial-build-a-default-vhd-or-vhdx)
  - [Build VHD or VHDX](#build-vhd-or-vhdx)
  - [Use Hyper-V to Boot Your Image](#use-hyper-v-to-boot-your-image)
- [Tutorial: Build the default ISO](#tutorial-build-the-default-iso)

## Tutorial: Build the Default ISO

In this tutorial, we will create a bootable ISO image for installing CBL-Mariner to either a physical machine or virtual hard drive.

The toolkit ships with several image configurations. The [image config files](https://github.com/microsoft/CBL-Mariner/blob/1.0/toolkit/docs/formats/imageconfig.md) define how a CBL-Mariner image is layed out once built or installed.  Each image config will also include a list of packages to install.

These can be built using the tools outside the core repo. Build the default ISO by invoking the following build command from the _CBL-MarinerTutorials/toolkit_ folder.

```bash
sudo make iso CONFIG_FILE=./imageconfigs/full.json
```

The first time `make image` is invoked, the toolkit downloads the necessary toolchain packages from the CBL-Mariner package repo at [packages.microsoft.com](packages.microsoft.com).  These toolchain packages are the standard set needed to build any local packages.  Once the toolchain is ready, `make` automatically proceeds to build any local packages.  In this case, the core repo's image configs do not use any of the packages located in the Tutorial repo so nothing will be built. `make` will then assemble the packages gathered from the package server to build the specified image.

The resulting ISO is placed in the `CBL-MarinerTutorials/out/full` folder.

### Use Hyper-V to Boot Your ISO Installer

See [Use Hyper-V to Boot Your ISO Installer](boot.md#use-hyper-v-to-boot-your-iso-installer) for instructions on using Hyper-V to boot the ISO.

## Tutorial: Build a Default VHD or VHDX

The tools can also create offline images that can be directly booted.

### Build VHD or VHDX

The tools can also build offline images for direct use in VMs or as containers:

```bash
# VHDX
sudo make image CONFIG_FILE=./imageconfigs/core-efi.json 
# VHD
sudo make image CONFIG_FILE=./imageconfigs/core-legacy.json
```

The resulting images are placed in the `CBL-MarinerTutorials/out` folder:

> VHDX:       `CBL-MarinerTutorials/out/images/core-efi/`
> VHD:        `CBL-MarinerTutorials/out/images/core-legacy/`

### Build the cloud-init configuration image

No user account is provisioned by default in most images.  To sign-in to these images, the sample meta-user-data.iso image must also be built and installed in your VM's CD drive.  The cloud-init service will detect the iso and provision a user account and password.

```Bash
# Build the cloud-init configuration image
# The output image is ../out/images/meta-user-data.iso
sudo make meta-user-data
```

### Use Hyper-V to Boot Your Image

See [Use Hyper-V to Boot Your Offline Image](boot.md#use-hyper-v-to-boot-your-offline-image) for instructions on using Hyper-V to boot the image and add a user profile with the `meta-user.iso` file.
