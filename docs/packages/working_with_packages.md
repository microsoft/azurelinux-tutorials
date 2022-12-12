# Working with Packages

- [Image Config File](#image-config-file)
    - [File Paths](#file-paths)
    - [Package Lists](#package-lists)
- [Tutorial: Customize your Image with Pre-built Packages](#tutorial-customize-your-image-with-pre-built-packages)
    - [Add Latest Pre-Built Package](#add-latest-pre-built-package)
    - [Add Specific Pre-Built Package Version](#add-specific-pre-built-package-version)
    - [Add Packages from Other RPM Repositories](#add-packages-from-other-rpm-repositories)
- [Tutorial: Customize your Image with Unsupported Packages](#tutorial-customize-your-image-with-unsupported-packages)

## Image Config File

### File Paths

Any **relative** file path referring to a file on the **build machine** is by default relative to the directory containing the config file itself. In case of this project, all config files are located inside the `imageconfigs` directory, so for a post-install script with a path of `postinstallscripts/demo_script.sh`, the tooling will look for `[repo_path]/imageconfigs/postinstallscripts/demo_script.sh`.

This default path can be changed by setting the `CONFIG_BASE_DIR` argument to a different directory.

All of the **absolute** paths are not affected.

Any file paths on the **built image** should always be absolute. Refer to the `AdditionalFiles` map in this project's config files for an example of using both the relative paths referring to files on the build machine and absolute paths referring to the paths, where these files should appear on the built image.

### Package Lists

In this section we will focus on how the image content is defined. In later sections, we will learn how to build a specific image or iso by passing a CONFIG_FILE argument to make. Each CONFIG_FILE specifies how the image should be built and what contents should be added to it.

The complete package set of an image is defined in the "PackageLists" array of each image's configuration file.  For example, the demo_vhd.json file includes these package lists:

   ```json
    "PackageLists": [
                "demo_package_lists/core-packages.json",
                "demo_package_lists/demo-packages.json"
            ],
   ```

Each package list defines the set of packages to include in the final image. In this example, there are two, so the resulting demo VHD contains the union of the two package lists.  While it is possible to combine both package lists into a single JSON file, the separation adds clarity by grouping related content.  In this case, packages originating from packages.microsoft.com are in the core-packages set, and packages built from the local repository are specified in the demo-packages set.

The first package list, core-packages.json, includes a superset-package called [core-packages-base-image](https://github.com/microsoft/CBL-Mariner/blob/1.0/SPECS/core-packages/core-packages.spec).  Core-packages-base-image is common to most derivatives as it contains the common set of packages used in Mariner Core.  This bundling is a convenience.  It is possible to list each package individually instead.  The second package, initramfs, is used for booting CBL-Mariner in either a virtualized or physical hardware environment.  Not every image needs it, so it's not included in the `core-packages-base-image` superset.  Instead, it's specified separately.

   ```json
    {
       "packages": [
            "core-packages-base-image",
            "initramfs"
       ],
    }
   ```

The second package list, demo-packages.json, contains the Hello World and os-subrelease packages that are unique to the CBL-MarinerTutorials repository:

   ```json
   {
       "packages": [
           "hello_world_demo",
           "os-subrelease"
       ]
   }
   ```

## Tutorial: Customize your Image with Pre-built Packages

In the previous section we described how the package lists are defined.  In this tutorial we will add a pre-built package to the core-packages.json file.

### Add Latest Pre-Built Package

The Zip package is not included in your demo image by default.  Because Zip is already released for CBL-Mariner lets add it to your demo image.  Open the [core-packages.json](./imageconfigs/demo_package_lists/core-packages.json) file with your favorite editor,  Add zip to the packages array before initramfs.  While it's possible to add zip after initramfs, it is currently recommended to insert new packages before initramfs due to a performance quirk in the build system.

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
cd CBL-MarinerTutorials/toolkit
sudo make image CONFIG_FILE=../imageconfigs/demo_vhd.json
```
Boot the image and verify that the latest version of zip is now provided:

```bash
    root@demo [~]# zip
    Copyright (c) 1990-2008 Info-ZIP - Type 'zip -"L"' for software license.
    Zip 3.0 (July 5th 2008). Usage:
    (...)
    root@demo [~]# tdnf info -y zip
    Installed Packages
    Name        : zip
    Version     : 3.0   <---\
    Release     : 5.cm2 <---|--- Your Version+Release will be greater than or equal to this version
    
```

By default the _latest_ version of any package specified in a package list will be included in your image.  It is important to note that each time you rebuild your image it may differ from your previous build as the packages on packages.microsoft.com are periodically updated to resolve security vulnerabilities. This behavior may or may not be desired, but you can always be assured that the most recent build is also the most up to date with respect to CVE's. 

If you want to guarantee that your next build will be reproduced the same way at a later time, CBL-Mariner provides some support for this. Each time an image is built, a summary file is generated that lists the explicit packages included in the build.  The default location of this file is at: _CBL-MarinerTutorials/build/pkg_artifacts/graph_external_deps.json_.  To capture your build's explicit contents and reproduce the build later, it's important to save this file for later use.  See [Reproducing a Build](https://github.com/microsoft/CBL-Mariner/blob/2.0/toolkit/docs/building/building.md#reproducing-a-build) in the CBL-Mariner git repository for advanced details.

The next section also describes a technique for pinning specific package versions.

### Add Specific Pre-Built Package Version

Occassionally you may need to install a very specific version of a package in your image at build time, rather than the latest version. CBL-Mariner supports this capability.

This time let's add `unzip` version 6.0-19, and the latest dash release for `etcd` version 3.5.1 to your demo image.  You do this in the following way:

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
cd CBL-MarinerTutorials/toolkit
sudo make image CONFIG_FILE=../imageconfigs/demo_vhd.json
```

Boot the image and verify that `unzip` in now provided, _and_ it is the 6.0-19 version.
Similarly, `etcd` is version 3.5.1, latest release.

```bash
    root@demo [~]# tdnf info -y unzip
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
    root@demo [~]# tdnf info -y etcd
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
### Add Packages from Other RPM Repositories

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

## Tutorial: Customize your Image with Unsupported Packages

In the previous tutorial we described how pre-existing packages can be added to your demo image.  In this tutorial we will walk through the process of adding a new package that Mariner does not formally support through the addition of a SPEC file.  

Packages are defined by RPM SPEC files. At its core, a SPEC file contains the instructions for building and installing a package.  Most SPEC files contain a pointer to one or more compressed source files, pointers to patch files, and the name, version and licensing information associated with the package.  SPEC files also contain references to build and runtime dependencies. 

The goal of this tutorial is to show the process for adding a SPEC file to the tutorial repo, not to delve into the details of creating a SPEC file.  For detailed information on SPEC file syntax and features refer to the [RPM Packaging Guide](https://rpm-packaging-guide.github.io/), the [RPM Reference Manual](https://rpm-software-management.github.io/rpm/manual/), or search the web as needed.

To add a new package to the CBL-MarinerTutorials repo you must take the following actions:
- [Acquire the compressed source file (the tarball) you want to build](#acquire-the-compressed-source-file)
- [Create a signature meta-data file (a SHA-256 hash of the tarball)](#create-a-signature-meta-data-file)
- [Create a .spec file](#create-a-spec-file)

For this tutorial we will add the "gnuchess" package to your CBL-MarinerTutorials image.

### Acquire the Compressed Source File

First, download the source code for gnuchess 6.2.7 [here](https://ftp.gnu.org/gnu/chess/gnuchess-6.2.7.tar.gz).  And save it in a new CBL-MarinerTutorials/SPECS/gnuchess folder.  Also, download and save the [game data file](http://ftp.gnu.org/pub/gnu/chess/book_1.01.pgn.gz) to the gnuchess folder.

Next, create the SPEC file for gnuchess.  This may be created from scratch, but in many cases it's easiest to leverage an open source version as a template.  Since the focus of this tutorial is to demonstrate how to quickly add a new package, we will obtain an existing SPEC file [Fedora source rpm for gnuchess](https://src.fedoraproject.org/rpms/gnuchess/blob/master/f/gnuchess.spec).

Clone the Fedora gnuchess repo and copy the SPEC and patch files into your gnuchess folder:
```bash
cd CBL-MarinerTutorials/SPECS/gnuchess
git clone https://src.fedoraproject.org/rpms/gnuchess.git /tmp/gnuchess
pushd /tmp/gnuchess
git checkout 03a6481
popd
cp /tmp/gnuchess/gnuchess.spec .
```

### Create a Signature Meta-data File

Now calculate the SHA-256 hashed for gnuchess-6.2.7.tar.gz and the book_1.01.pgn.gz file  The SHA-256 sum is used by the build system as an integrity check to ensure that the tarballs associated with a SPEC file are the expected one.

Calculate the new checksum:
```bash
$ cd CBL-MarinerTutorials/SPECS/gnuchess
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

At this point your CBL-MarinerTutorials/SPECS/gnuchess folder should look similar to this:

```bash
~/CBL-MarinerTutorials/SPECS/gnuchess$ ls -la
total 816
drwxr-xr-x 2 jon jon   4096 Jan 22 14:23 .
drwxr-xr-x 5 jon jon   4096 Jan 22 13:43 ..
-rw-r--r-- 1 jon jon    338 Jan 22 14:23 gnuchess-5.06-bookpath.patch
-rw-r--r-- 1 jon jon 802863 Jan 22 13:44 gnuchess-6.2.7.tar.gz
-rw-r--r-- 1 jon jon    117 Jan 22 13:51 gnuchess.signatures.json
-rw-r--r-- 1 jon jon   9965 Jan 22 14:23 gnuchess.spec
```

### Create a .spec File

Now, we need to modify the gnuchess.spec file slightly to build properly for CBL-Mariner by:
- bumping the release number
- selecting the non-precompiled book
- patching the BuildRequires for c++ to use the CBL-Mariner package name
- updating the %changelog and professionally show gratitude to Fedora

Your SPEC file should appear similar to this:

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

Also, modify the %changelog by adding a new entry similar to the one below.

```
%changelog

*Thu Jan 21 2021 Your Name Here <your_email_here> - 6.2.7-4      
- First version of gnuchess for my image. Spec file imported from Fedora.

* Sat Aug 01 2020 Fedora Release Engineering <releng@fedoraproject.org> - 6.2.7-3
- Second attempt - Rebuilt for
  https://fedoraproject.org/wiki/Fedora_33_Mass_Rebuild
```
For more information on editing SPEC files, refer to RPM's [Spec file format](https://rpm-software-management.github.io/rpm/manual/spec.html) guide and the RPM packaging guide on [SPEC files][https://rpm-packaging-guide.github.io/#what-is-a-spec-file].

Next, you can check your SPEC file to ensure that it conforms with RPM design rules. See the RPM packaging guide on [Checking RPMs](https://rpm-packaging-guide.github.io/#checking-rpms-for-sanity) for how to use the *rpmlint* tool.

At this point, we can use a shortcut to verify that the gnu chess package compiles by issuing the following command.  It will build any packages not already built, but not build the image itself.

```bash
$ cd CBL-MarinerTutorials/toolkit
$ sudo make build-packages CONFIG_FILE=
```

If the build fails, inspect the build output for clues and repair any issues.  The default location for build logs is in the 
_CBL-MarinerTutorials/build/logs/pkggen/rpmbuilding/_ folder.  There should be one log for each package.

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
cd CBL-MarinerTutorials/toolkit
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
