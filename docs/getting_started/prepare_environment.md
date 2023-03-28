# Tutorial: Prepare your Environment

Before starting this tutorial, you will need to setup your development machine.  These instructions were tested on an x86_64 based machine using Ubuntu 20.04.

- [Install Tools](#install-tools)
- [Clone CBL-Mariner](#clone-cbl-mariner-and-build-the-toolkit)
- [Clone CBL-MarinerTutorials](#clone-cbl-marinertutorials-repo-and-extract-the-toolkit)

## Install Tools

These tools are required for building both the toolkit and the images built from the toolkit.  These are the same [prerequisites needed for building CBL-Mariner](https://github.com/microsoft/CBL-Mariner/blob/2.0/toolkit/docs/building/prerequisites.md).

```bash
# Add a backports repo in order to install the necessary version of Go.
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt-get update

# Install required dependencies.
sudo apt -y install git make tar wget curl rpm qemu-utils golang-1.17-go genisoimage python bison gawk

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

You can also setup this environment on CBL-Mariner
```bash
# Install required dependencies.
sudo dnf -y install git make tar wget curl rpm golang genisoimage python bison gawk glibc-devel binutils kernel-headers
```
You may want to install rpmlint, in this case you need to add the extended repo in /etc/yum.repos.d/ as mariner-extended.repo
```bash
[mariner-official-extended]
name=CBL-Mariner Official Extended $releasever $basearch
baseurl=https://packages.microsoft.com/cbl-mariner/$releasever/prod/extended/$basearch
gpgkey=file:///etc/pki/rpm-gpg/MICROSOFT-RPM-GPG-KEY file:///etc/pki/rpm-gpg/MICROSOFT-METADATA-GPG-KEY
gpgcheck=1
repo_gpgcheck=1
enabled=1
skip_if_unavailable=True
sslverify=1
```

At the moment docker does not support Mariner.

## Clone CBL-Mariner and Build the Toolkit

To build the CBL-MarinerTutorials repository you will need the same toolkit and makefile from the CBL-Mariner repository.  So, first clone CBL-Mariner, and then checkout the stable release of interest (e.g. 1.0-stable or 2.0-stable), then build the toolkit.

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

## Clone CBL-MarinerTutorials Repo and Extract the Toolkit

Now clone the CBL-MarinerTutorials repo and extract the toolkit to the CBL-MarinerTutorials repository.  

```bash
git clone https://github.com/microsoft/CBL-MarinerTutorials.git
pushd CBL-MarinerTutorials
cp ../CBL-Mariner/out/toolkit-*.tar.gz ./
tar -xzvf toolkit-*.tar.gz
```

The toolkit folder now contains the makefile, support scripts and the go tools compiled from the section.  The toolkit will preserve the previously compiled tool binaries, however the toolkit is also able to rebuild them if desired. (Not recommended: set `REBUILD_TOOLS=y` to use locally rebuilt tool binaries during a build). For more information on our toolkit see [How The Build System Works](https://github.com/microsoft/CBL-Mariner/blob/2.0/toolkit/docs/how_it_works/0_intro.md) in the CBL-Mariner repo.  

The remainder of this tutorial assumes you are using CBL-Mariner 2.0.  However, it is possible to build the same from this tutorial using the CBL-Mariner 1.0 release as well.
