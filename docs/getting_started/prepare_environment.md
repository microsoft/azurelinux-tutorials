# Tutorial: Prepare your Environment

Before starting this tutorial, you will need to setup your development machine.  These instructions were tested on an x86_64 based machine using Ubuntu 22.04 and Azure Linux 2.0.

- [Install Tools](#install-tools)
- [Clone AzureLinux](#clone-azure-linux-and-build-the-toolkit)
- [Clone AzureLinux-Tutorials](#clone-azure-linux-tutorials-repo-and-extract-the-toolkit)

## Install Tools

Get the prerequisites for building the tools. Instructions are provided for both Ubuntu and Azure Linux at [prerequisites needed for building Azure Linux](https://github.com/microsoft/azurelinux/blob/-/toolkit/docs/building/prerequisites.md).

## Clone Azure Linux and Build the Toolkit

To build the `Azurelinux-Tutorials` repository you will need the same toolkit and makefile from the `Azurelinux` repository.  So, first clone `Azurelinux`, and then checkout the stable release of interest (e.g. 3.0-stable), then build the toolkit.

### Example for Azurelinux 3.0 Toolkit

```bash
git clone -b 3.0-stable https://github.com/microsoft/azurelinux.git
sudo make -C azurelinux/toolkit -j20 package-toolkit REBUILD_TOOLS=y
```

## Clone Azure Linux Tutorials Repo and Extract the Toolkit

Now clone the `Azurelinux-Tutorials` repo and extract the toolkit to the Azurelinux-Tutorials repository.  

```bash
git clone https://github.com/microsoft/azurelinux-tutorials.git
pushd azurelinux-tutorials
cp ../azurelinux/out/toolkit-*.tar.gz ./
tar -xzvf toolkit-*.tar.gz
cd ./toolkit
```

The toolkit folder now contains the makefile, support scripts and the go tools compiled in [this section](#clone-azure-linux-and-build-the-toolkit). The toolkit will preserve the previously compiled tool binaries, however the toolkit is also able to rebuild them if desired. (Not recommended: set `REBUILD_TOOLS=y` to use locally rebuilt tool binaries during a build). For more information on our toolkit see [How The Build System Works](https://github.com/microsoft/azurelinux/blob/-/toolkit/docs/how_it_works/0_intro.md) in the Azure Linux repo.  
