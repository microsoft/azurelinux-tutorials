# Modifying the Kernel

## Tutorial: Modify the Image Kernel

In some situations you may want to build and test variations of the default CBL-Mariner Kernel.  Because the kernel is also a package, the process is similar to adding a new package as discussed in the previous section.  

To begin, copy the complete contents of the CBL-Mariner kernel spec folder into your clone of the CBL-MarinerTutorials repo.  The following assumes you have already cloned CBL-Mariner and the CBL-MarinerTutorials repo and both are nested under a git folder:

```bash
user@machine:~/git$ cp -r CBL-Mariner/SPECS/kernel/ CBL-MarinerTutorials/SPECS/kernel/ 
```
Next, we will need to download a source tarball from github that matches the kernel version in the kernel.spec file.

```bash
# Switch to the kernel folder
$ cd CBL-MarinerTutorials/SPECS/kernel/ 

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
cd CBL-MarinerTutorials/toolkit
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
