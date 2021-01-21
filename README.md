# **Introduction**
While it is possible to clone CBL-Mariner and directly build or images from that environment, it is not the recommended approach.  Usually it is best to work in a smaller, problem focused environment where you can custom build just what you need, and rely on the fact that the curated CBL-Mariner packages are already available in the cloud. In this way, you can customize an image with a disk layout your prefer or augment CBL-Mariner by building packages that CBL-Mariner may not provide.  If you are building a product based on CBL-Mariner, you may want your own repository with just the minimal set of packages for your business needs.  The CBL-MarinerDemo repo provides a basic template for creating a CBL-Mariner based product (aka a Derivative Image) or for experimenting with CBL-Mariner in the most efficient way.

When you build an ISO, VHD or VHDX image from the CBL-MarinerDemo repository the resulting image will contain additional content unavailable in the CBL-Mariner repo.  The repository demonstrates how you can augment CBL-Mariner without forking the CBL-Mariner repository.  This repository contains a SPEC file and source for building a simple "Hello World" application.  This repository also includes a simple "os-subrelease" package that allows you to add information about your derivative to an /etc/os-subrelease file in your CBL-Mariner derivative.  

The following tutorial will guide you through the process of building the basic CBL-MarinerDemo image as well as basic guidance for customizing your image or building your own package.

# **Build Demo Image**

## **Clone CBL-Mariner and Build the Toolkit**
To build the CBL-MarinerDemo repository you will need the same toolkit at makefile from the CBL-Mariner repository.  So, first build clone CBL-Mariner and build the toolkit.

```bash
git clone https://github.com/microsoft/CBL-Mariner.git
git checkout 1.0-stable
pushd CBL-Mariner/toolkit
sudo make go-tools REBUILD_TOOLS=y
popd
```

## **Clone CBL-MarinerDemo Repo and Copy the Toolkit**
Now clone the CBL-MarinerDemo repo and copy the tools to the CBL-MarinerDemo repository.

```bash
git clone https://github.com/microsoft/CBL-MarinerDemo.git
cp -r CBL-Mariner/toolkit CBL-MarinerDemo/toolkit
```

## **Build Derivate VHD or VHDX**
Now build an image.  The first time this command is invoked the toolkit downloads the necessary toolchain packages from the CBL-Mariner repository at packages.microsoft.com.  These toolchain packages are the standard set needed to build any local packages contained in the CBL-MarinerDemo repo.  Once the toolchain is ready, make will proceed to building any local packages.  In this case, the [Hello World](./SPECS/hello_world_demo/hello_world_demo.spec) and [OS-Subrelease](./SPECS/os-subrelease/os-subrelease.spec) packages will be compiled.  After all local packages are built, make will assemble all packages to build an image.

```bash
cd CBL-MarinerDemo/toolkit
sudo make image CONFIG_FILE=../imageconfigs/demo_vhd.json
sudo make image CONFIG_FILE=../imageconfigs/demo_vhdx.json
```
The resulting binaries (images and rpms) are placed in the CBL-MarinerDemo/out folder

    VHDX:       `CBL-MarinerDemo/out/images/demo_vhdx/`
    VHD:        `CBL-MarinerDemo/out/images/demo_vhd/`
    PACKAGES:   
The local demo packages are placed in CBL-MarinerDemo/out/RPMS/x86_64/`

## **Use Hyper-V to Boot Your Demo Image**
Copy your demo VHD or VHDX image to your Windows Machine and boot it with Hyper-V.    

#### **Create VHD(X) Virtual Machine with Hyper-V**

1. From Hyper-V Select Action->New->Virtual Machine.
1. Provide a name for your VM and press Next >.
1. For VHD select `Generation 1`. For VHDX select `Generation 2`, then press Next >.
1. Change Memory size if desired, then press Next >.
1. Select a virtual switch, then press Next >.
1. Select Use an existing virtual hard disk, then browse and select your VHD(X) file.
1. Press Finish.

#### **[Gen2/VHDX Only] Fix Boot Options**

1. Right click your virtual machine from Hyper-V Manager
1. Select Settings....
1. Select Security and disable Enable Secure Boot.

#### **Boot and Sign-In to Your VHD(X) Image**

1. Right click your VM and select Connect....
1. Select Start.
1. Wait for CBL-Mariner to boot to the login prompt, then sign in with:
    ```bash
    root
    p@ssw0rd
    ```
#### **Run Hello World**
From the command line run the helloworld program

    ```bash
    root@demo [~]# helloworld
    Hello World Sample!
    ```
Now show the contents of the os-subrelease file

    ```bash
    root@demo [~]# cat /etc/os-subrelease
    BUILDER_NAME=My Builder Name
    BUILD_DATE="YYYY-MM-DDTHH:MM:SSZ"
    ID=my-product-id
    VERSION_ID=my-version-id
    NAME="My Product Name"
    VERSION="my-version-id"
    ```
Congratulations you've built and launched your first CBL-Mariner derivative image.

# Package Lists

In the previous section, we described how to build a specific image by passing a CONFIG_FILE argument to make. Each CONFIG_FILE specifies how the image should be built and what contents should be added to it.  In this section we will focus on how the image content is defined.  

The complete set of packages added to an image is defined in the "PackageLists" array of each image's imageconfig file.  For example, the demo_vhd.json file includes these package lists:

```json
 "PackageLists": [
                "demo_package_lists/core-packages.json",
                "demo_package_lists/demo-packages.json"
            ],
```

Each package list defines the set of packages to include in the final image. In this example, there are two, so the resuling demo vhd image contains the union of the two package sets.  While it is possible to combine both package lists into a single JSON file, the separation adds clarity by grouping related content.  In this case, packages originating from packages.microsoft.com are in the core-packages set, and packages built from the local repository are added to the demo-packages set.

The first package list, core-packages.json, includes a superset-package called [core-packages-base-image](https://github.com/microsoft/CBL-Mariner/blob/1.0/SPECS/core-packages/core-packages.spec).  Core-packages-base-iamge is common to most derivatives as it contains the common set of packages used in Mariner Core.  The second package, initramfs, is used for booting CBL-Mariner in a Hyper-V or physical hardware environment.  Not every image needs it, so it's not included inthe core-packages-base-image and is added.

```json
 {
    "packages": [
        "core-packages-base-image",
        "initramfs"
    ],
}
```

Unsurprinsingly, the demo-packages.json file contains the Hello World and os-subrelease packages that are provided by the demo repo:

```json
{
    "packages": [
        "hello_world_demo",
        "os-subrelease"
    ]
}
```

# Adding Pre-built Package to Demo Image

In the previous section we described how the package lists are defined.  In this section we will add a pre-built package to the core-packages.json file.

## Add Latest V

The Zip package is not included in the demo image by default.  Because Zip is already released for CBL-Mariner lets add it to your demo image.  Open the [core-packages.json](./imageconfigs/demo_package_lists/core-packages.json) file with your favorite editor,  Add zip to the packages array before initramfs.  While it's possible to add zip after initramfs, this is currently not recommended due to a quirk in the build system that may cause the regeneration of certain packages like kernel.

```json
 {
    "packages": [
        "core-packages-base-image",
        "zip",                        <----- add zip here
        "initramfs"
    ],
}
```
Save the file and rebuild the image of your choice (The ISO, VHD and VHDX all share the same package list file.) 

```bash
pushd CBL-MarinerDemo/toolkit
sudo make image CONFIG_FILE=../imageconfigs/demo_vhd.json
```

```bash
pushd CBL-MarinerDemo/toolkit
sudo make iso CONFIG_FILE=../imageconfigs/demo_iso.json
```

## Build Derivate VHD or VHDX
