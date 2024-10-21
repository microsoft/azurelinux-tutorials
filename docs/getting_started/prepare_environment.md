# Tutorial: Prepare your Environment

Before starting this tutorial, you will need to setup your development machine.  These instructions were tested on an x86_64 based machine running Ubuntu 22.04 and a machine running Azure Linux 2.0.

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

```bash
# Your directories should look like this now
tree -L 2
#.
#└── azurelinux
#    ├── build
#    ├── ccache
#    ├── cgmanifest.json
#    ├── CODE_OF_CONDUCT.md
#    ├── codeql3000.yml
#    ├── CONTRIBUTING.md
#    ├── LICENSE
#    ├── LICENSES-AND-NOTICES
#    ├── out
#    ├── README.md
#    ├── SECURITY.md
#    ├── SPECS
#    ├── SPECS-EXTENDED
#    ├── SPECS-SIGNED
#    ├── SUPPORT.md
#    └── toolkit

tree -L 1 ./azurelinux/out/
#./azurelinux/out/
#├── images
#├── RPMS
#├── rpms_snapshot.json
#├── SRPMS
#└── toolkit-3.0.20241021.1514-x86_64.tar.gz    <---- This is the toolkit that was built
```

## Clone Azure Linux Tutorials Repo and Extract the Toolkit

Now clone the `Azurelinux-Tutorials` repo and extract the toolkit to the Azurelinux-Tutorials repository.

```bash
git clone https://github.com/microsoft/azurelinux-tutorials.git
tar -xzvf ./azurelinux/out/toolkit-*.tar.gz -C ./azurelinux-tutorials
pushd ./azurelinux-tutorials/toolkit
```

```bash
# The layout should now look like this
tree -L 2
#.
#├── azurelinux
#│   ├── build
#│   ├── ccache
#│   ├── cgmanifest.json
#│   ├── CODE_OF_CONDUCT.md
#│   ├── codeql3000.yml
#│   ├── CONTRIBUTING.md
#│   ├── LICENSE
#│   ├── LICENSES-AND-NOTICES
#│   ├── out
#│   ├── README.md
#│   ├── SECURITY.md
#│   ├── SPECS
#│   ├── SPECS-EXTENDED
#│   ├── SPECS-SIGNED
#│   ├── SUPPORT.md
#│   └── toolkit
#└── azurelinux-tutorials
#    ├── build-in-container
#    ├── CODE_OF_CONDUCT.md
#    ├── docs
#    ├── imageconfigs
#    ├── imaging-from-packer
#    ├── LICENSE
#    ├── README.md
#    ├── SECURITY.md
#    ├── SPECS
#    └── toolkit    <---- You are here
```

The toolkit folder now contains the makefile, support scripts and the go tools compiled in [this section](#clone-azure-linux-and-build-the-toolkit). The toolkit will preserve the previously compiled tool binaries, however the toolkit is also able to rebuild them if desired. (Not recommended: set `REBUILD_TOOLS=y` to use locally rebuilt tool binaries during a build). For more information on our toolkit see [How The Build System Works](https://github.com/microsoft/azurelinux/blob/-/toolkit/docs/how_it_works/0_intro.md) in the Azure Linux repo.  
