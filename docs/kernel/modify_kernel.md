# Modifying the Kernel

## Tutorial: Modify the Image Kernel

In some situations, you may want to build and test variations of the default CBL-Mariner kernel.  Because the `kernel` is also a package, the process is similar to adding a new package as discussed in the previous section.  

### Prep your Kernel SPEC Environment
The following assumes you have already completed the [Prepare your Environment](docs/getting_started/prepare_environment.md) steps. To begin creating a custom kernel, copy the contents of the CBL-Mariner `kernel` spec folder into your clone of the `CBL-MarinerTutorials` repo.

```bash
#
# The following assumes CBL-Mariner and CBL-MarinerTutorials were cloned under a folder named `git`
#

# Copy all the kernel contents to CBL-MarinerTutorials
user@machine:~/git$ cp -r CBL-Mariner/SPECS/kernel/ CBL-MarinerTutorials/SPECS/kernel/
#
# ---or---
#
# Copy only the kernel building components to CBL-MarinerTutorials
user@machine:~/git$ rsync -a  --exclude 'CVE*' CBL-Mariner/SPECS/kernel CBL-MarinerTutorials/SPECS/ 
```

Next, we will need to download a source tarball from [CBL-Mariner-Linux-Kernel](https://github.com/microsoft/CBL-Mariner-Linux-Kernel). We will choose the tag which matches the `kernel` version in the `kernel.spec` file.

```bash
# Switch to the kernel folder
$ cd CBL-MarinerTutorials/SPECS/kernel/ 

# Determine the kernel version you are using (yours may vary)
$ grep Version: kernel.spec
Version:        5.15.102.1

# Download the associated tar.gz file from https://github.com/microsoft/CBL-Mariner-Linux-Kernel. Be sure to substitute your Mariner version and kernel version numbers.
$ wget -O kernel-5.15.102.1.tar.gz https://github.com/microsoft/CBL-Mariner-Linux-Kernel/archive/refs/tags/rolling-lts/mariner-2/5.15.102.1.tar.gz
```

Update the signature for the source. **This only is needed if you are using a different version than the original spec file.**

```bash
# Get the hash for the source tar
SOURCEHASH=$(sha256sum kernel-5.15.102.1.tar.gz | awk '{print $1}')

# Update the hash for the source tar in the signatures file
sed -i 's/    "kernel-5.15.102.1.tar.gz": .*/    "kernel-5.15.102.1.tar.gz": "'"$SOURCEHASH"'"/' kernel.signatures.json
```

### Customize a Kernel

Now you can  make your modifications to the necessary config files.  
* For AMD64, modify the `config` file.  
* For AARCH64, modify the `config_aarch64` file.  

At the time of writing this tutorial, the CONFIG_BLK_WBT setting is disabled by default. For this tutorial, we will enable it. 

```bash
sed -i 's/# CONFIG_BLK_WBT is not set/CONFIG_BLK_WBT=y/' config
```

After editing your config file, save it and update the signature.

```bash
# Get the hash for the config file
CONFIGHASH=$(sha256sum config | awk '{print $1}')

# Update the hash for the config in the signatures file
sed -i 's/    "config": .*/    "config": "'"$CONFIGHASH"'",/' kernel.signatures.json
```

One last step before building.  When there is a conflict, the build system will make a best-effort attempt at prioritizing the local version of a package over the version on packages.microsoft.com.  However, to ensure we can differentiate our new custom kernel from the default kernel, and to guarantee the local version will be consumed, bump the release number in the kernel release spec. In this case, use your favorite editor and change the release number to 100 as shown below and save the file.

```bash
Summary:        Linux Kernel
Name:           kernel
Version:        5.15.102.1
Release:        100%{?dist}               <------------------ set this value to 100 (for example)
License:        GPLv2
Vendor:         Microsoft Corporation
Distribution:   Mariner
```

### Build a Custom Kernel
Let's build the new kernel RPM.

```bash
# Enter the toolkit
cd ../../toolkit

# Build the kernel package
# THIS WILL FAIL. This is intended for the purposes of this tutorial
sudo make build-packages REBUILD_TOOLS=y CONFIG_FILE= PACKAGE_REBUILD_LIST="kernel"
```

You should see build failures have occured.

```bash
INFO[0068] Failed SRPMs:                                
INFO[0068] --> kernel-5.15.102.1-100.cm2.src.rpm , error: exit status 2, for details see: /home/user/repos/CBL-MarinerDemo/build/logs/pkggen/rpmbuilding/kernel-5.15.102.1-100.cm2.src.rpm.log 
```

Looking at the log `CBL-MarinerDemo/build/logs/pkggen/rpmbuilding/kernel-5.15.102.1-100.cm2.src.rpm.log` we see:

```bash
# For readability, time stamps removed
"+ cat config_diff"
"--- new_config\t2023-04-07 04:31:15.263160807 +0000"
"+++ current_config\t2023-04-07 04:31:12.255183015 +0000"
# ...
"@@ -862,7 +862,6 @@"
" CONFIG_BLK_DEV_THROTTLING=y"
" # CONFIG_BLK_DEV_THROTTLING_LOW is not set"
" CONFIG_BLK_WBT=y"
"-CONFIG_BLK_WBT_MQ=y"
" # CONFIG_BLK_CGROUP_IOLATENCY is not set"
" # CONFIG_BLK_CGROUP_IOCOST is not set"
" # CONFIG_BLK_CGROUP_IOPRIO is not set"
# ...
"Config file has unexpected changes"
"Update config file to set changed values explicitly"
```

We see the error message `"Config file has unexpected changes... Update config file to set changed values explicitly"`. This is a common error when editing configs. CBL-Mariner's `kernel` requires implicitly enabled settings to be explicitly set. In this case, enabling only `CONFIG_BLK_WBT` is insufficient. We also need `CONFIG_BLK_WBT_MQ` to be explicitly set. The logs show that the `kernel` spec (specifically `make oldconfig`) has noted that `CONFIG_BLK_WBT_MQ` is missing. Because `CONFIG_BLK_WBT_MQ` is missing, compilation of the kernel fails.  In general, when an error of this nature occurs, the build log file for the kernel will indicate what needs to be changed.  

</br>

Let's fix this build error and rebuild.

```bash
# Enter kernel spec folder
pushd ../SPECS/kernel

# Update the config file with missing CONFIG_BLK_WBT_MQ=y
sed -i '/CONFIG_BLK_WBT=y/a\CONFIG_BLK_WBT_MQ=y' config

# Update the signature file
CONFIGHASH=$(sha256sum config | awk '{print $1}')
sed -i 's/    "config": .*/    "config": "'"$CONFIGHASH"'",/' kernel.signatures.json

# Go back to toolkit
popd

# Rebuild the kernel. This will take some time. Watch the log file to see if it reaches the %build phase
sudo make build-packages REBUILD_TOOLS=y CONFIG_FILE= PACKAGE_REBUILD_LIST="kernel"
```

If successful, you will see a message like this:

```bash
INFO[2416] ---------------------------                  
INFO[2416] --------- Summary ---------                  
INFO[2416] ---------------------------                  
INFO[2416] Number of built SRPMs:             1         
INFO[2416] Number of prebuilt SRPMs:          2         
INFO[2416] Number of failed SRPMs:            0         
INFO[2416] Number of blocked SRPMs:           0         
INFO[2416] Number of unresolved dependencies: 0         
INFO[2416] Built SRPMs:                                 
INFO[2416] --> kernel-5.15.102.1-100.cm2.src.rpm   
```

You can also see the built RPM in `CBL-MarinerTutorials/out/RPMS/`. This RPM can be `scp`'d to a running image and installed via `sudo rpm -ihv kernel-5.15.102.1-100.cm2.rpm`.

### Build an Image with a Custom Kernel

We can also build an image with our new kernel. Note that even if we hadn't prebuilt the kernel in the previous steps, this step would also rebuild the kernel RPM.

```bash
# Enter the toolkit
cd CBL-MarinerTutorials/toolkit

# Clean our build environment
sudo make clean

# Make an image
sudo make image CONFIG_FILE=../imageconfigs/demo_vhd.json
```

After the build completes, boot your image and log in.  Next, verify that you have your modified kernel.
```bash
# Verify your kernel's version and release number (this may vary)
root@demo: uname -r
5.15.102.1-100.cm2
```
