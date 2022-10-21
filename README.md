
# Introduction

The [CBL-Mariner](https://github.com/microsoft/CBL-Mariner) repository provides detailed instructions for building CBL-Mariner from end-to-end.  While it is possible to clone CBL-Mariner and build packages or images from that environment, for most users, it is _not the recommended approach_.  Usually it is best to work in a smaller, problem focused environment where you can quickly build just what you need, and rely on the fact that the curated CBL-Mariner packages are already available in the cloud. In this way, you can customize an image with your preferred disk layout or adding supplemental packages that CBL-Mariner may not provide.  If you are building a product based on CBL-Mariner, you may want your own repository with just the minimal set of packages for your business needs.  This repo, the CBL-MarinerDemo repo, provides a basic template for getting started.  From here you can create a CBL-Mariner based product (aka a Derivative Image) or you may generate quick experimental or debug builds to try out new ideas.

When you build an ISO, VHD or VHDX image from this repository,  the resulting image will contain additional content unavailable in the CBL-Mariner repo.  The CBL-MarinerDemo repository demonstrates how you can augment CBL-Mariner without forking the CBL-Mariner repository.  This repository contains the SPEC file and source for building a simple "Hello World" application.  This repository also includes a simple "os-subrelease" package that allows you to add identifying information about your derivative to an /etc/os-subrelease file.  

The following tutorial guides you through the process of building and running the basic CBL-MarinerDemo image.  These instructions also describe how to customize or extend the basic CBL-MarinerDemo image.

# Table of Contents

[Prequisites: Prepare your Environment](#Prequisites-Prepare-your-Environment)

[Build Demo VHD or VHDX Image](#build-demo-vhd-or-vhdx)

[Build Demo ISO Image](#build-demo-iso)

[Image config file](#image-config-file)

[Customize Demo Image with Pre-built Packages](#customize-demo-image-with-pre-built-packages)

[Customize Demo Image with New Packages](#customize-demo-image-with-new-packages)

[Modify the Demo Image Kernel](#modify-the-demo-image-kernel)

[Automate VHD or VHDX creation 'packer'](imaging-from-packer/Readme.md)

# Prequisites: Prepare your Environment

Before starting this tutorial, you will need to setup your development machine.  These instructions were tested on an x86_64 based machine using Ubuntu 18.04.

## Install Tools

These tools are required for building both the toolkit and the images built from the toolkit.  These are the same [prerequisites needed for building CBL-Mariner](https://github.com/microsoft/CBL-Mariner/blob/2.0/toolkit/docs/building/prerequisites.md).

```bash
# Add a backports repo in order to install the necessary version of Go.
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt-get update

# Install required dependencies.
sudo apt -y install git make tar wget curl rpm qemu-utils golang-1.17-go genisoimage python-minimal bison gawk

# Recommended but not required: `pigz` for faster compression operations.
sudo apt -y install pigz

# Fix go 1.17 link
sudo ln -vsf /usr/lib/go-1.17/bin/go /usr/bin/go

# Install Docker.
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

**You will need to log out and lock back in** for user changes to take effect.


## Clone CBL-Mariner and Build the Toolkit

To build the CBL-MarinerDemo repository you will need the same toolkit and makefile from the CBL-Mariner repository.  So, first clone CBL-Mariner, and then checkout the stable release of interest (e.g. 1.0-stable or 2.0-stable), then build the toolkit.

### Example for CBL-Mariner 1.0 Toolkit
```bash
git clone https://github.com/microsoft/CBL-Mariner.git
pushd CBL-Mariner/toolkit
git checkout 1.0-stable
sudo make package-toolkit REBUILD_TOOLS=y
popd
```
### Example for CBL-Mariner 2.0 Toolkit 
```bash
git clone https://github.com/microsoft/CBL-Mariner.git
pushd CBL-Mariner/toolkit
git checkout 2.0-stable
sudo make package-toolkit REBUILD_TOOLS=y
popd
```

## Clone CBL-MarinerDemo Repo and Extract the Toolkit

Now clone the CBL-MarinerDemo repo and extract the toolkit to the CBL-MarinerDemo repository.  

```bash
git clone https://github.com/microsoft/CBL-MarinerDemo.git
pushd CBL-MarinerDemo
cp ../CBL-Mariner/out/toolkit-*.tar.gz ./
tar -xzvf toolkit-*.tar.gz
```

The toolkit folder now contains the makefile, support scripts and the go tools compiled from the section.  The toolkit will preserve the previously compiled tool binaries, however the toolkit is also able to rebuild them if desired. (Not recommended: set `REBUILD_TOOLS=y` to use locally rebuilt tool binaries during a build).

# Working with Preview Releases

The remainder of this tutorial assumes you are using CBL-Mariner 2.0.  However, it is possible to build this Demo using the CBL-Mariner 1.0 Release as well.  

For example:
```bash
sudo make image CONFIG_FILE=../imageconfigs/demo_vhd.json USE_PREVIEW_REPO=y
```

# Build Demo VHD or VHDX

In the previous section we configured your build machine.  In this section we will build a VHD or VHD(X) image.  

## Build Derivate VHD or VHDX

Choose an image to build by invoking one of the following build commands from the _CBL-MarinerDemo/toolkit_ folder.

```bash
sudo make image CONFIG_FILE=../imageconfigs/demo_vhd.json 
sudo make image CONFIG_FILE=../imageconfigs/demo_vhdx.json
```

The first time make image is invoked the toolkit downloads the necessary toolchain packages from the CBL-Mariner repository at packages.microsoft.com.  These toolchain packages are the standard set needed to build any local packages contained in the CBL-MarinerDemo repo.  Once the toolchain is ready, make automatically proceeds to build any local packages.  In this case, the [Hello World](./SPECS/hello_world_demo/hello_world_demo.spec) and [OS-Subrelease](./SPECS/os-subrelease/os-subrelease.spec) packages will be compiled.  After all local packages are built, make will assemble the packages to build an image.
The resulting binaries (images and rpms) are placed in the CBL-MarinerDemo/out folder

    VHDX:       `CBL-MarinerDemo/out/images/demo_vhdx/`
    VHD:        `CBL-MarinerDemo/out/images/demo_vhd/`
    PACKAGES:   `CBL-MarinerDemo/out/RPMS/x86_64/`


## Use Hyper-V to Boot Your Demo Image
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
1. Select _Settings...._
1. Select Security and under _Template:_ select _Microsoft UEFI Certificate Authority_.

**Boot and Sign-In to Your VHD(X) Image**

1. Right click your VM and select _Connect..._.
1. Select _Start_.
1. Wait for CBL-Mariner to boot to the login prompt, then sign in with:
```bash
    root
    p@ssw0rd
```
**Verify your Derivate Packages are Installed**
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
Congratulations you've built and launched your first CBL-Mariner derivative image.

# Build Demo ISO

In the previous section we learned how to create a simple VHD(X) image. In this section we will turn our attention to creating a bootable ISO image for installing CBL-Mariner to either a physical machine or virtual hard drive. 

Let's jump right in.  Run the following command to build the demo ISO:

```bash
cd CBL-MarinerDemo/toolkit
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
1. Select _Install an operating system from a bootable image file_ and browse to your Demo ISO. 
1. Press _Finish_.

**[Gen2/VHDX Only] Fix Boot Options**

1. Right click your virtual machine from Hyper-V Manager
1. Select _Settings..._
1. Select Security and under _Template:_ select _Microsoft UEFI Certificate Authority_.
1. Select Firmware and adjust the boot order so DVD is first and Hard Drive is second.
1. Select _Apply_ to apply all changes.

**Boot ISO**
1. Right click your VM and select _Connect..._.
1. Select _Start_.
1. Follow the Installer Prompts to Install your image
1. When installation completes, select restart to reboot the machine. The installation ISO will be automatically ejected.
1. When prompted sign in to your CBL-Mariner system using the user name and password provisioned through the Installer.

# Image config file

## File paths

Any **relative** file path referring to a file on the **build machine** is by default relative to the directory containing the config file itself. In case of this project, all config files are located inside the `imageconfigs` directory, so for a post-install script with a path of `postinstallscripts/demo_script.sh`, the tooling will look for `[repo_path]/imageconfigs/postinstallscripts/demo_script.sh`.

This default path can be changed by setting the `CONFIG_BASE_DIR` argument to a different directory.

All of the **absolute** paths are not affected.

Any file paths on the **built image** should always be absolute. Refer to the `AdditionalFiles` map in this project's config files for an example of using both the relative paths referring to files on the build machine and absolute paths referring to the paths, where these files should appear on the built image.

## Package Lists

In the previous sections, we learned how to build a specific image or iso by passing a CONFIG_FILE argument to make. Each CONFIG_FILE specifies how the image should be built and what contents should be added to it.  In this section we will focus on how the image content is defined.  

The complete package set of an image is defined in the "PackageLists" array of each image's configuration file.  For example, the demo_vhd.json file includes these package lists:

   ```json
    "PackageLists": [
                "demo_package_lists/core-packages.json",
                "demo_package_lists/demo-packages.json"
            ],
   ```

Each package list defines the set of packages to include in the final image. In this example, there are two, so the resuling demo VHD contains the union of the two package lists.  While it is possible to combine both package lists into a single JSON file, the separation adds clarity by grouping related content.  In this case, packages originating from packages.microsoft.com are in the core-packages set, and packages built from the local repository are specified in the demo-packages set.

The first package list, core-packages.json, includes a superset-package called [core-packages-base-image](https://github.com/microsoft/CBL-Mariner/blob/1.0/SPECS/core-packages/core-packages.spec).  Core-packages-base-image is common to most derivatives as it contains the common set of packages used in Mariner Core.  This bundling is a convenience.  It is possible to list each package individually instead.  The second package, initramfs, is used for booting CBL-Mariner in either a virtualized or physical hardware environment.  Not every image needs it, so it's not included in the `core-packages-base-image` superset.  Instead, it's specified separately.

   ```json
    {
       "packages": [
            "core-packages-base-image",
            "initramfs"
       ],
    }
   ```

The second package list, demo-packages.json, contains the Hello World and os-subrelease packages that are unique to the CBL-MarinerDemo repository:

   ```json
   {
       "packages": [
           "hello_world_demo",
           "os-subrelease"
       ]
   }
   ```

# Customize Demo Image with Pre-built Packages

In the previous section we described how the package lists are defined.  In this section we will add a pre-built package to the core-packages.json file.

## Add Latest Pre-Built Package

The Zip package is not included in the demo image by default.  Because Zip is already released for CBL-Mariner lets add it to your demo image.  Open the [core-packages.json](./imageconfigs/demo_package_lists/core-packages.json) file with your favorite editor,  Add zip to the packages array before initramfs.  While it's possible to add zip after initramfs, it is currently recommended to insert new packages before initramfs due to a performance quirk in the build system.

```json
 {
    "packages": [
        "core-packages-base-image",
        "zip",                        <----- add zip here
        "initramfs"
    ],
}
```
Save the file.  For this tutorial we will continue building the VHD image, but you may rebuild the image of your choice because the ISO, VHD and VHDX all share the same core package list file.

```bash
cd CBL-MarinerDemo/toolkit
sudo make image CONFIG_FILE=../imageconfigs/demo_vhd.json
```
Boot the image and verify that the latest version of zip is now provided:

```bash
    root@demo [~]# zip
    Copyright (c) 1990-2008 Info-ZIP - Type 'zip -"L"' for software license.
    Zip 3.0 (July 5th 2008). Usage:
    (...)
    root@demo [~]# dnf info -y zip
    Installed Packages
    Name        : zip
    Version     : 3.0   <---\
    Release     : 5.cm2 <---|--- Your Version+Release will be greater than or equal to this version
    
```

By default the _latest_ version of any package specified in a package list will be included in your image.  It is important to note that each time you rebuild your image it may differ from your previous build as the packages on packages.microsoft.com are periodically updated to resolve security vulernabilities. This behavior may or may not be desired, but you can always be assured that the most recent build is also the most up to date with respect to CVE's. 

If you want to guarantee that your next build will be reproduced the same way at a later time, CBL-Mariner provides some support for this. Each time an image is built, a summary file is generated that lists the explicit packages included in the build.  The default location of this file is at: _CBL-MarinerDemo/build/pkg_artifacts/graph_external_deps.json_.  To capture your build's explicit contents and reproduce the build later, it's important to save this file for later use.  See [Reproducing a Build](https://github.com/microsoft/CBL-Mariner/blob/2.0/toolkit/docs/building/building.md#reproducing-a-build) in the CBL-Mariner git repository for advanced details.

The next section also describes a technique for pinning specific package versions.

## Add Specific Pre-Built Package Version

Occassionally you may need to install a very specific version of a package in your image at build time, rather than the latest version. CBL-Mariner supports this capability.

This time let's add `unzip` version 6.0-19, and the latest dash release for `etcd` version 3.5.1 to our demo image.  You do this in the following way:

```json
{
    "packages": [
        "core-packages-base-image",
        "etcd=3.5.1",         <---- add specific 'etcd' version
        "zip",
        "unzip=6.0-19.cm2",   <---- add specific 'unzip' version and release
        "initramfs"
    ],
}
```

**NOTE**: Release fields always have the `.[mariner_release]` suffix (`.cm2` in our case). Specifying only the version without the release number will always get you the latest release for the chosen version.

Save the file and rebuild your image.

```bash
cd CBL-MarinerDemo/toolkit
sudo make image CONFIG_FILE=../imageconfigs/demo_vhd.json
```

Boot the image and verify that `unzip` in now provided, _and_ it is the 6.0-19 version.
Similarly, `etcd` is version 3.5.1, latest release.

```bash
    root@demo [~]# dnf info -y unzip
    Installed Packages
    Name        : unzip
    Version     : 6.0
    Release     : 19.cm2
    (...)
    Available Packages
    Name        : unzip
    Version     : 6.0     <--- this field may vary
    Release     : 20.cm2  <--- this field may vary
    (...)
    root@demo [~]# dnf info -y etcd
    Installed Packages
    Name        : etcd
    Version     : 3.5.1
    Release     : 3.cm2   <--- this field may vary, but should be the latest release version available
    (...)
    Available Packages
    Name        : etcd
    Version     : 3.5.1  <--- this field may vary
    Release     : 2.cm2   <--- this field may vary
    ...
```
## Adding packages from other RPM repositories

It is possible to build your images and packages using pre-built RPMs from repositories other than the default CBL-Mariner ones. In order to inform the toolkit to access them during the build, you have to make use of the [REPO_LIST](https://github.com/microsoft/CBL-Mariner/blob/2.0/toolkit/docs/building/building.md#repo_list) argument where you specify .repo files pointing to the additional repositories.

Example:

Let's say your CBL-Mariner 2.0 image requires the `indent` package.  This package is available inside the [CBL-Mariner Extended Repository](http://packages.microsoft.com/cbl-mariner/2.0/prod/extended/x86_64/) and the corresponding .repo file pointing to Mariner's official RPM repository hosting its packages is available in the toolkit under `toolkit/repos/mariner-extended.repo`. With that you'll be able to build your image by first adding `indent` to your package list:

```json
 {
    "packages": [
        "core-packages-base-image",
        "zip",
        "indent",                   <----- added indent here
        "initramfs"
    ],
}
```

and then by running the following command:

```bash
sudo make image CONFIG_FILE=../imageconfigs/demo_vhd.json REPO_LIST=repos/mariner-extended.repo
```

CBL-Mariner's toolkit provides other .repo files under `toolkit/repos`. Refer to the [REPO_LIST documentation](https://github.com/microsoft/CBL-Mariner/blob/2.0/toolkit/docs/building/building.md#repo_list) for more details.

# Customize Demo Image with New Packages

In the previous section we described how pre-existing packages can be added to the Demo image.  In this section we will walk through the process of adding a new package.  

Packages are defined by RPM SPEC files. At its core, a SPEC file contains the instructions for building and installing a package.  Most SPEC files contain a pointer to one or more compressed source files, pointers to patch files, and the name, version and licensing information associated with the package.  SPEC files also contain references to build and runtime dependencies. The goal of this tutorial is to show the process for adding a spec file to the demo repo, not to delve into the details of creating a spec file.  For detailed information on SPEC file syntax and features refer to the [RPM Packaging Guide](https://rpm-packaging-guide.github.io/) or search the web as needed.

To add a new package to the CBL-MarinerDemo repo you must take the following actions:
- Acquire the compressed source file (the tarball) you want to build
- Create a signature meta-data file (a SHA-256 hash of the tarball)
- Create a .spec file.  

For this tutorial we will add the "gnuchess" package to your CBL-MarinerDemo image.

First, download the source code for gnuchess 6.2.7 [here](https://ftp.gnu.org/gnu/chess/gnuchess-6.2.7.tar.gz).  And save it in a new CBL-MarinerDemo/SPECS/gnuchess folder.  Also, download and save the [game data file](http://ftp.gnu.org/pub/gnu/chess/book_1.01.pgn.gz) to the gnuchess folder.

Next, create the spec file for gnuchess.  This may be created from scratch, but in many cases it's easiest to leverage an open source version as a template.  Since the focus of this tutorial is to demonstrate how to quickly add a new package, we will obtain an existing spec file [Fedora source rpm for gnuchess](https://src.fedoraproject.org/rpms/gnuchess/blob/master/f/gnuchess.spec).

Clone the Fedora gnuchess repo and copy the spec and patch files into your gnuchess folder:
```bash
cd CBL-MarinerDemo/SPECS/gnuchess
git clone https://src.fedoraproject.org/rpms/gnuchess.git /tmp/gnuchess
pushd /tmp/gnuchess
git checkout 03a6481
popd
cp /tmp/gnuchess/gnuchess.spec .
```

Now calculate the SHA-256 hashed for gnuchess-6.2.7.tar.gz and the book_1.01.pgn.gz file  The SHA-256 sum is used by the build system as an integrity check to ensure that the tarballs associated with a SPEC file are the expected one.

Calculate the new checksum:
```bash
$ cd CBL-MarinerDemo/SPECS/gnuchess
$ sha256sum gnuchess-6.2.7.tar.gz
e536675a61abe82e61b919f6b786755441d9fcd4c21e1c82fb9e5340dd229846  gnuchess-6.2.7.tar.gz
$ sha256sum book_1.01.pgn.gz
35df43a342c73e6624e8dbfed78d588c2085208168c3cd3300295e3c57981be0  book_1.01.pgn.gz

```
Using your favorite editor create and save a gnuchess.signatures.json file with the following content.

```json
{
 "Signatures": {
  "gnuchess-6.2.7.tar.gz": "e536675a61abe82e61b919f6b786755441d9fcd4c21e1c82fb9e5340dd229846",
  "book_1.01.pgn.gz": "35df43a342c73e6624e8dbfed78d588c2085208168c3cd3300295e3c57981be0"
 }
}
```

At this point your CBL-MarinerDemo/SPECS/gnuchess folder should alook similar to this:

```bash
~/CBL-MarinerDemo/SPECS/gnuchess$ ls -la
total 816
drwxr-xr-x 2 jon jon   4096 Jan 22 14:23 .
drwxr-xr-x 5 jon jon   4096 Jan 22 13:43 ..
-rw-r--r-- 1 jon jon    338 Jan 22 14:23 gnuchess-5.06-bookpath.patch
-rw-r--r-- 1 jon jon 802863 Jan 22 13:44 gnuchess-6.2.7.tar.gz
-rw-r--r-- 1 jon jon    117 Jan 22 13:51 gnuchess.signatures.json
-rw-r--r-- 1 jon jon   9965 Jan 22 14:23 gnuchess.spec
```

At this point we need to modify the gnuchess.spec file slightly to build properly for CBL-Mariner by:
- bumping the release number
- selecting the non-precompiled book
- patching the BuildRequires for c++ to use the CBL-Mariner package name
- updating the changelog and professionally show grattitude to Fedora.

Your spec file should appear similar to this:

```
Summary: The GNU chess program
Name: gnuchess
Version: 6.2.7
Release: 4%{?dist}     <------------------------------------------ increment this value
License: GPLv3+
URL: ftp://ftp.gnu.org/pub/gnu/chess/
Source: ftp://ftp.gnu.org/pub/gnu/chess/%{name}-%{version}.tar.gz
Source1: http://ftp.gnu.org/pub/gnu/chess/book_1.01.pgn.gz <------ uncomment this line
# use precompiled book.dat:
#Source1: book_1.02.dat.gz  <------------------------------------- comment out this line
#Patch0: gnuchess-5.06-bookpath.patch
Provides: chessprogram
BuildRequires:  gcc  <-------------------------------------------- set this to gcc (or remove)
BuildRequires: flex, gcc
BuildRequires: make
```

Also, modify the changelog by adding a new entry similar to the one below.

```
%changelog

*Thu Jan 21 2021 Your Name Here <your_email_here> - 6.2.7-4      
- First version of gnuchess for my image. Spec file imported from Fedora.

* Sat Aug 01 2020 Fedora Release Engineering <releng@fedoraproject.org> - 6.2.7-3
- Second attempt - Rebuilt for
  https://fedoraproject.org/wiki/Fedora_33_Mass_Rebuild
```

At this point, we can use a shortcut to verify that the gnu chess package compiles by issuing the following command.  It will build any packages not already built, but not build the image itself.

```bash
$ cd CBL-MarinerDemo/toolkit
$ sudo make build-packages CONFIG_FILE=
```

If the build fails, inspect the build output for clues and repair any issues.  The default location for build logs is in the 
_CBL-MarinerDemo/build/logs/pkggen/rpmbuilding/_ folder.  There should be one log for each package.

Finally, we need to add gnuchess to the demo-packages.json file.

```json
   {
       "packages": [
         "gnuchess",
         "hello_world_demo",
         "os-subrelease"
       ]
   }
```

Save your demo-packages.json file and rebuild your image.

```bash
cd CBL-MarinerDemo/toolkit
sudo make image CONFIG_FILE=../imageconfigs/demo_vhd.json
```

Boot your image, log in and verify that gnuchess is now available:

```bash
    root@demo [~]# gnuchess
    GNU Chess 6.2.7
    Copyright (C) 2020 Free Software Foundation, Inc.
    License GPLv3+ GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.
    White (1) :
```

# Modify the Demo Image Kernel

In some situations you may want to build and test variations of the default CBL-Mariner Kernel.  Because the kernel is also a package, the process is similar to adding a new package as discussed in the previous section.  

To begin, copy the complete contents of the CBL-Mariner kernel spec folder into your clone of the CBL-MarinerDemo repo.  The following assumes you have already cloned CBL-Mariner and the CBL-MarinerDemo demo repo and both are nested under a git folder:

```bash
user@machine:~/git$ cp -r CBL-Mariner/SPECS/kernel/ CBL-MarinerDemo/SPECS/kernel/ 
```
Next, we will need to download a source tarball from github that matches the kernel version in the kernel.spec file.

```bash
# Switch to the kernel folder
$ cd CBL-MarinerDemo/SPECS/kernel/ 

# Determine the kernel version you are using (yours may vary)
$ grep Version: kernel.spec
Version:        5.4.91

# Download the associated tar.gz file.  Be sure to substitute your version number in the URL here
$ wget  https://github.com/microsoft/WSL2-Linux-Kernel/archive/linux-msft-5.4.91.tar.gz
```

Now make your modifications to the one or both of the config files.  For AMD64 modify the `config` file.  For AARCH64, modify the `config_aarch64` file.  

By default the CONFIG_MAGIC_SYSRQ setting is disabled.  For this tutorial we will enable it. Using your favorite editor open the config file.  Find the CONFIG_MAGIC_SYSRQ setting, then make the adjustments as shown here:
```bash
# Before
# CONFIG_MAGIC_SYSRQ is not set

# After
CONFIG_MAGIC_SYSRQ=y
CONFIG_MAGIC_SYSRQ_DEFAULT_ENABLE=0x1
CONFIG_MAGIC_SYSRQ_SERIAL=y
```

Note that the kernel spec file, from the CBL-Mariner repo, requires implicitly enabled settings to be explicitly set.  In this case enabling CONFIG_MAGIC_SYSRQ is insufficient because CONFIG_MAGIC_SYSRQ_DEFAULT_ENABLE and CONFIG_MAGIC_SYSRQ_SERIAL are implicitly enabled.  If they were missing, compilation of the kernel would fail.  In general, when an error of this nature occurs, the build log file for the kernel will indicate what needs to be changed.  For example, if we _only_ set CONFIG_MAGIC_SYSRQ=y, the build would eventually fail with the build output shown here:

```
time="2021-02-05T11:16:15-08:00" level=debug msg="Magic SysRq key (MAGIC_SYSRQ) [Y/n/?] y"
time="2021-02-05T11:16:15-08:00" level=debug
time="2021-02-05T11:16:15-08:00" level=debug msg="Error in reading or end of file."
time="2021-02-05T11:16:15-08:00" level=debug msg="  Enable magic SysRq key functions by default (MAGIC_SYSRQ_DEFAULT_ENABLE) [0x1] (NEW) "
time="2021-02-05T11:16:15-08:00" level=debug
time="2021-02-05T11:16:15-08:00" level=debug msg="Error in reading or end of file."
time="2021-02-05T11:16:15-08:00" level=debug msg="  Enable magic SysRq key over serial (MAGIC_SYSRQ_SERIAL) [Y/n/?] (NEW) "
.
.
.
time="2021-02-05T11:16:15-08:00" level=debug msg="+ cat config_diff"
time="2021-02-05T11:16:15-08:00" level=debug msg="--- new_config\t2021-02-05 19:16:15.316175432 +0000"
time="2021-02-05T11:16:15-08:00" level=debug msg="+++ current_config\t2021-02-05 19:16:09.440117553 +0000"
time="2021-02-05T11:16:15-08:00" level=debug msg="@@ -6484,8 +6484,6 @@"
time="2021-02-05T11:16:15-08:00" level=debug msg=" # end of Compile-time checks and compiler options"
time="2021-02-05T11:16:15-08:00" level=debug msg=" "
time="2021-02-05T11:16:15-08:00" level=debug msg=" CONFIG_MAGIC_SYSRQ=y"
time="2021-02-05T11:16:15-08:00" level=debug msg="-CONFIG_MAGIC_SYSRQ_DEFAULT_ENABLE=0x1"
time="2021-02-05T11:16:15-08:00" level=debug msg="-CONFIG_MAGIC_SYSRQ_SERIAL=y"
time="2021-02-05T11:16:15-08:00" level=debug msg=" CONFIG_DEBUG_KERNEL=y"
time="2021-02-05T11:16:15-08:00" level=debug msg=" CONFIG_DEBUG_MISC=y"
time="2021-02-05T11:16:15-08:00" level=debug msg=" "
```

After editing your config file, save it and compute a new sha256sum.

```bash
$ sha256sum config
f6c3c5eb536f7c7778c3aaa45984de9bf6c58d2a7e5dfd74ace203faabf090a6  config
```

Now, using your favorite editor update the config file hash(es) in the kernel.signatures.json.

One last step before building.  When there is a conflict, the build system will make a best-effort attempt at prioritizing the local version of a package over the version on packages.microsoft.com.  However, to ensure we can differentiate our new custom kernel from the default kernel, and to guarantee the local version will be consumed, bump the release number in the kernel release spec. In this case use your favorite editor and change the release number to 100 as shown below and save the file.

```
Summary:        Linux Kernel
Name:           kernel
Version:        5.4.91
Release:        100%{?dist}               <------------------ set this value to 100 (for example)
License:        GPLv2
Vendor:         Microsoft Corporation
Distribution:   Mariner
```

After saving your file, rebuild your demo image.  The kernel will take some time to build.

```bash
cd CBL-MarinerDemo/toolkit
sudo make clean
sudo make image CONFIG_FILE=../imageconfigs/demo_vhd.json
```

After the build completes, boot your image and log in.  Next, verify that you have your modified kernel and that you can trigger a sysrq function.

```bash
    # Verify your kernel's version and release number (this may vary)
    root@demo [~]# uname -r
    5.4.91-100.cm2

    # Verify that sysrq functionality is enabled in the kernel.  
    # There are several ways to do this, but we'll directly write the
    # reboot command to /proc/sysrq-trigger 
    root@demo [~]# echo b > /proc/sysrq-trigger
```
