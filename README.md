# **Introduction**

The CBL-Mariner repository provides detailed instructions on building CBL-Mariner from end-to-end.  While it is possible to clone CBL-Mariner and build packages or images from that environment, it is _not the recommended approach_ for most users.  Usually it is best to work in a smaller, problem focused environment where you can quickly build just what you need, and rely on the fact that the curated CBL-Mariner packages are already available in the cloud. In this way, you can customize an image with your preferred disk layout or adding supplemental packages that CBL-Mariner may not provide.  If you are building a product based on CBL-Mariner, you may want your own repository with just the minimal set of packages for your business needs.  This repo, the CBL-MarinerDemo repo, provides a basic template for getting started.  From here you can create a CBL-Mariner based product (aka a Derivative Image) or you may generate quick experimental or debug builds to try out new ideas.

When you build an ISO, VHD or VHDX image from this repository,  the resulting image will contain additional content unavailable in the CBL-Mariner repo.  The CBL-MarinerDemo repository demonstrates how you can augment CBL-Mariner without forking the CBL-Mariner repository.  This repository contains the SPEC file and source for building a simple "Hello World" application.  This repository also includes a simple "os-subrelease" package that allows you to add identifying information about your derivative to an /etc/os-subrelease file.  

The following tutorial guides you through the process of building and running the basic CBL-MarinerDemo image.  These instructions also describe how to customize or extend the basic CBL-MarinerDemo image.

# **Build Demo Image**

## **Clone CBL-Mariner and Build the Toolkit**
To build the CBL-MarinerDemo repository you will need the same toolkit and makefile from the CBL-Mariner repository.  So, first clone CBL-Mariner and build the toolkit.

```bash
git clone https://github.com/microsoft/CBL-Mariner.git
git checkout 1.0-stable
pushd CBL-Mariner/toolkit
sudo make go-tools REBUILD_TOOLS=y
popd
```

## **Clone CBL-MarinerDemo Repo and Copy the Toolkit**

Now clone the CBL-MarinerDemo repo and copy the toolkit to the CBL-MarinerDemo repository.  

```bash
git clone https://github.com/microsoft/CBL-MarinerDemo.git
cp -r CBL-Mariner/toolkit CBL-MarinerDemo/toolkit
```

The toolkit folder now contains the makefile, support scripts and the go tools compiled from the section.  It is recommended at this point to move the compiled tools to a new folder to prevent them from being scrubbed in a make clean situation.

```bash
cd CBL-Mariner/toolkit 
mv ./out/tools/ CBL-Mariner/tools/
```

## **Build Derivate VHD or VHDX**
Now build an image.  The first time this command is invoked the toolkit downloads the necessary toolchain packages from the CBL-Mariner repository at packages.microsoft.com.  These toolchain packages are the standard set needed to build any local packages contained in the CBL-MarinerDemo repo.  Once the toolchain is ready, make proceeds to build any local packages.  In this case, the [Hello World](./SPECS/hello_world_demo/hello_world_demo.spec) and [OS-Subrelease](./SPECS/os-subrelease/os-subrelease.spec) packages will be compiled.  After all local packages are built, make will assemble all packages to build an image.

```bash
cd CBL-MarinerDemo/toolkit
sudo make image CONFIG_FILE=../imageconfigs/demo_vhd.json
sudo make image CONFIG_FILE=../imageconfigs/demo_vhdx.json
```
The resulting binaries (images and rpms) are placed in the CBL-MarinerDemo/out folder

    VHDX:       `CBL-MarinerDemo/out/images/demo_vhdx/`
    VHD:        `CBL-MarinerDemo/out/images/demo_vhd/`
    PACKAGES:   `CBL-MarinerDemo/out/RPMS/x86_64/`


## **Use Hyper-V to Boot Your Demo Image**
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
1. Select Security and **disable** _Enable Secure Boot_.

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

# Package Lists

In the previous section, we described how to build a specific image by passing a CONFIG_FILE argument to make. Each CONFIG_FILE specifies how the image should be built and what contents should be added to it.  In this section we will focus on how the image content is defined.  

The complete package set of an image is defined in the "PackageLists" array of each image's image configuration file.  For example, the demo_vhd.json file includes these package lists:

   ```json
    "PackageLists": [
                "demo_package_lists/core-packages.json",
                "demo_package_lists/demo-packages.json"
            ],
   ```

Each package list defines the set of packages to include in the final image. In this example, there are two, so the resuling demo VHD contains the union of the two package lists.  While it is possible to combine both package lists into a single JSON file, the separation adds clarity by grouping related content.  In this case, packages originating from packages.microsoft.com are in the core-packages set, and packages built from the local repository are added to the demo-packages set.

The first package list, core-packages.json, includes a superset-package called [core-packages-base-image](https://github.com/microsoft/CBL-Mariner/blob/1.0/SPECS/core-packages/core-packages.spec).  Core-packages-base-iamge is common to most derivatives as it contains the common set of packages used in Mariner Core.  The second package, initramfs, is used for booting CBL-Mariner in either a virtualized or physical hardware environment.  Not every image needs it, so it's not included in the `core-packages-base-image` superset.  Instead, it's specified separately.

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

# Adding Pre-built Packages to an Image

In the previous section we described how the package lists are defined.  In this section we will add a pre-built package to the core-packages.json file.

## Add Latest Pre-Built Package

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
    ...
    root@demo [~]# dnf info -y zip
    Installed Packages
    Name        : zip
    Version     : 3.0   <---\
    Release     : 5.cm  <---|--- Your Version+Release will be greater than or equal to this version
    
```

By default the _latest_ version of any package specified in a package list will be included in your image.  It is important to note that each time you rebuild your image it may differ from your previous build as the packages on packages.microsoft.com are periodically updated to resolve security vulernabilities. This behavior may or may not be desired, but you can always be assured that the most recent build is also the most up to date with respect to CVE's. 

If you want to reproduce your build at a later time, CBL-Mariner provides some support for this. Each time an image is built, a summary file is generated that lists the explicit packages included in the build.  The default location of this file is at: _CBL-MarinerDemo/build/pkg_artifacts/graph_external_deps.json_.  To capture your build's explicit contents and reproduce the build later, it's important to save this file for later use.  See [Reproducing a Build](https://github.com/microsoft/CBL-Mariner/blob/1.0/toolkit/docs/building/building.md#reproducing-a-build) in the CBL-Mariner git repository for advanced details.

The next section also describes a technique for pinning specific package versions.

## Add Specific Pre-Built Package Version

Occassionally you may need to install a very specific version of a package in your image at build time, rather than the latest version. CBL-Mariner supports this capability.

This time lets add Unzip version 6.0-16 to our demo image.  To do this, you must specify the full name and architecture of your preferred package.

```json
 {
    "packages": [
        "core-packages-base-image",
        "zip",
        "unzip-6.0-16.cm1.x86_64",   <---- add unzip here          
        "initramfs"
    ],
}
```

Save the file and rebuild your image.

```bash
cd CBL-MarinerDemo/toolkit
sudo make image CONFIG_FILE=../imageconfigs/demo_vhd.json
```
Boot the image and verify that unzip in now provided, _and_ it is the -16 version.

```bash
    root@demo [~]# dnf info -y unzip
    Installed Packages
    Name        : unzip
    Version     : 6.0
    Release     : 16.cm1
    ...
    Available Packages
    Name        : unzip
    Version     : 6.0
    Release     : 18.cm1  <--- this version may vary
    ...
```

# Adding New Packages to an Image

In the previous section we described how pre-existing packages can be added to the Demo image.  In this section we will walk through the process of adding a new package.  

Packages are defined by RPM SPEC files. At its core, a SPEC file contains the instructions for building and installing a package.  Most SPEC files contain a pointer to one or more compressed source files, pointers to patch files, and name, version and licensing information associated with the package.  SPEC files also contain references to build and runtime dependencies. The goal of this tutorial is to show the process for adding a spec file to the demo repo, not to delve into the details of creating a spec file.  For detailed information on SPEC file syntax and features refer to the [RPM Packaging Guide](https://rpm-packaging-guide.github.io/) or search the web as needed.

To add a new package to the CBL-MarinerDemo repo you must take the following actions:
- Acquire the compressed source file (the tarball) you want to build
- Create a signature meta-data file (a SHA-256 hash of the tarball)
- Create a .spec file.  

For this tutorial we will add the "gnuchess" package to your CBL-MarinerDemo image.

First, download the source code for gnuchess 6.2.7 [here](ftp://ftp.gnu.org/pub/gnu/chess/gnuchess-6.2.7.tar.gz).  And save it in a new CBL-MarinerDemo/SPECS/gnuchess folder.  Also, download and save the [game data file](http://ftp.gnu.org/pub/gnu/chess/book_1.01.pgn.gz) to the gnuchess folder.

Next, create the spec file for gnuchess.  This may be created from scratch, but in many cases it's easiest to leverage an open source version as a template.  Since the focus of this tutorial is to demonstrate how to quickly add a new package, we will obtain an existing spec file [Fedora source rpm for gnuchess](https://src.fedoraproject.org/rpms/gnuchess/blob/master/f/gnuchess.spec).

Clone the Fedora gnuchess repo and copy the spec and patch files into your gnuchess folder:
```bash
$ cd CBL-MarinerDemo/SPECS/gnuchess
$ git clone https://src.fedoraproject.org/rpms/gnuchess.git /tmp/gnuchess
$ cp /tmp/gnuchess/gnuchess.spec .
$ 
```

Now calculate the SHA-256 hashed for gnuchess-6.2.7.tar.gz and the book_1.01.pgn.gz file  The SHA-256 sum is used by the build system as an integrity check to ensure that the tarball associated with a SPEC file is the expected one.

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

Modify the gnuchess.spec file by:
- bumping the release number
- selecting the non-precompiled book
- patching the BuildRequires for c++ to use the CBL-Mariner package name
- updating the changelog and professionally show grattitude to Fedora.

Your spec file should appear similar to this:

```
Summary: The GNU chess program
Name: gnuchess
Version: 6.2.7
Release: 4%{?dist}                           <--- increment this value
License: GPLv3+
URL: ftp://ftp.gnu.org/pub/gnu/chess/
Source: ftp://ftp.gnu.org/pub/gnu/chess/%{name}-%{version}.tar.gz
Source1: http://ftp.gnu.org/pub/gnu/chess/book_1.01.pgn.gz      <---- uncomment this line
# use precompiled book.dat:
#Source1: book_1.02.dat.gz                                      <---- comment this line
#Patch0: gnuchess-5.06-bookpath.patch
Provides: chessprogram
BuildRequires:  gcc                          <--- set this to gcc
BuildRequires: flex, gcc
BuildRequires: make

...

%changelog
*Thu Jan 21 2021 Your Name Here <your_email_here> - 6.2.7-4      
- First version of gnuchess for my image. Spec file imported from Fedora.

* Sat Aug 01 2020 Fedora Release Engineering <releng@fedoraproject.org> - 6.2.7-3
- Second attempt - Rebuilt for
  https://fedoraproject.org/wiki/Fedora_33_Mass_Rebuild
```
At this point, we can verify that the gnu chess package compiles by issuing the following command

```bash
$ cd CBL-MarinerDemo/toolkit
$ sudo make build-packages CONFIG_FILE= TOOL_BINS_DIR=../tools
```

Finally, modify the demo-packages.json file by adding gnuchess to the image.

```json
   {
       "packages": [
         "gnuchess",
         "hello_world_demo",
         "os-subrelease"
       ]
   }
```

# Building an ISO

In the previous sections we learned how to create a simple VHD(X) image. In this section we will turn our attention to creating a bootable ISO image for installing CBL-Mariner to either a physical machine or virtual hard drive. 

Let's jump right in.  Run the following command to build the demo ISO

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
1. Select Security and disable _Enable Secure Boot_.
1. Select Firmware and adjust the boot order so DVD is first and Hard Drive is second.
1. Select _Apply_ to apply all changes.

**Boot ISO**
1. Right click your VM and select _Connect..._.
1. Select _Start_.
1. Follow the Installer Prompts to Install your image
1. When installation completes, select restart to reboot the machine. The installation ISO will be automatically ejected.
1. When prompted sign in to your CBL-Mariner system using the user name and password provisioned through the Installer.

