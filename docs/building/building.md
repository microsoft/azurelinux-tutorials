# Building

- [Tutorial: Build a Demo VHD or VHDX](#tutorial-build-a-demo-vhd-or-vhdx)
    - [Build Derivate VHD or VHDX](#build-derivate-vhd-or-vhdx)
    - [Use Hyper-V to Boot Your Demo Image](#use-hyper-v-to-boot-your-demo-image)
- [Tutorial: Build a Demo ISO](#tutorial-build-a-demo-iso)

## Tutorial: Build a Demo VHD or VHDX

In the previous tutorials, we configured your build machine, walked through how to add packages, and described how to modify the kernel.  In this tutorial, we will put it altogether and build a VHD or VHD(X) image.  

### Build Derivate VHD or VHDX

Choose an image to build by invoking one of the following build commands from the _CBL-MarinerTutorials/toolkit_ folder.

```bash
sudo make image CONFIG_FILE=../imageconfigs/demo_vhd.json 
sudo make image CONFIG_FILE=../imageconfigs/demo_vhdx.json
```

The first time make image is invoked the toolkit downloads the necessary toolchain packages from the CBL-Mariner repository at packages.microsoft.com.  These toolchain packages are the standard set needed to build any local packages contained in the CBL-MarinerTutorials repo.  Once the toolchain is ready, make automatically proceeds to build any local packages.  In this case, the [Hello World](./SPECS/hello_world_demo/hello_world_demo.spec) and [OS-Subrelease](./SPECS/os-subrelease/os-subrelease.spec) packages will be compiled.  After all local packages are built, make will assemble the packages to build an image.
The resulting binaries (images and rpms) are placed in the CBL-MarinerTutorials/out folder

    VHDX:       `CBL-MarinerTutorials/out/images/demo_vhdx/`
    VHD:        `CBL-MarinerTutorials/out/images/demo_vhd/`
    PACKAGES:   `CBL-MarinerTutorials/out/RPMS/x86_64/`

### Use Hyper-V to Boot Your Demo Image

See [Use Hyper-V to Boot Your Offline Image](../getting_started/boot.md#use-hyper-v-to-boot-your-offline-image) for instructions on using Hyper-V to boot the image and add a user profile with the `meta-user.iso` file.

**Verify your Packages are Installed**
From the command line run the helloworld program

    ```
    root@demo [~]# helloworld
    Hello World Sample!
    ```
Now show the contents of the os-subrelease file

    ```
    root@demo [~]# cat /etc/os-subrelease
    BUILDER_NAME=My Builder Name
    BUILD_DATE="YYYY-MM-DDTHH:MM:SSZ"
    ID=my-product-id
    VERSION_ID=my-version-id
    NAME="My Product Name"
    VERSION="my-version-id"
    ```
Congratulations you've built and launched your first CBL-Mariner derivative image!

## Tutorial: Build a Demo ISO

In the previous tutorial, we learned how to create a simple VHD(X) image. In this tutorial, we will turn our attention to creating a bootable ISO image for installing CBL-Mariner to either a physical machine or virtual hard drive.

Let's jump right in.  Run the following command to build a demo ISO:

```bash
cd CBL-MarinerTutorials/toolkit
sudo make iso CONFIG_FILE=../imageconfigs/demo_iso.json
```

### Use Hyper-V to Boot Your ISO Installer

See [Use Hyper-V to Boot Your ISO Installer](../getting_started/boot.md#use-hyper-v-to-boot-your-iso-installer) for instructions on using Hyper-V to boot the ISO.
