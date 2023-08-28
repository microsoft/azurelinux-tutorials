#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

echo "------------ Setting up Mariner Build Environment ------------"

# build variables
MARINER_BASE_DIR=/mariner
BUILD_DIR="$MARINER_BASE_DIR/build"
CCACHE_DIR="$MARINER_BASE_DIR/ccache"
CBL_MARINER_GIT_URL="https://github.com/microsoft/CBL-Mariner.git"
CHROOT_DIR="/temp/DockerStage/"
DISABLE_UPSTREAM_REPOS="n"
IMAGE_CONFIG_DIR="$MARINER_BASE_DIR/toolkit/imageconfigs"
LOG_LEVEL="info"
LOG_PUBLISH_DIR="$MARINER_BASE_DIR/logs"
MARINER_RELEASE_TAG="2.0-stable"
OUT_DIR="$MARINER_BASE_DIR/out"
RUN_CHECK="y"
SOURCE_URL="https://cblmarinerstorage.blob.core.windows.net/sources/core"
SPECS_DIR="$MARINER_BASE_DIR/SPECS"
USE_CCACHE="y"

# Build Mariner toolkit if not present, by cloning Mariner GitHub repo
#
# No arguments
# Global variables expected to be defined: BUILD_DIR, CHROOT_DIR, CHROOT_NB, OUT_DIR
download_mariner_toolkit() {
    if [ ! "$(ls -A toolkit)" ]; then
    echo "------------ Preparing Mariner toolkit ------------"
        if [ ! -d CBL-Mariner ]; then
            echo "------------ Cloning Mariner toolkit from github ------------"
            git clone \
                --branch ${MARINER_RELEASE_TAG} \
                --depth 1 \
                ${CBL_MARINER_GIT_URL}
        fi
        echo "------------ Building Mariner toolkit ------------"
        make -j$(nproc) \
            -C CBL-Mariner/toolkit \
            package-toolkit \
            BUILD_DIR="$BUILD_DIR" \
            CHROOT_DIR="$CHROOT_DIR" \
            CONCURRENT_PACKAGE_BUILDS="$CHROOT_NB" \
            CONFIG_FILE= \
            LOG_LEVEL=info \
            OUT_DIR="$OUT_DIR" \
            REBUILD_TOOLS=y && \
        rm -rf CBL-Mariner && \
        tar -xzvf ${OUT_DIR}/toolkit-*.tar.gz
    fi
}

# check if $SPECS_DIR is empty, and alert the user
check_specs() {
    if [ ! "$(ls -A $SPECS_DIR)" ]; then
        echo -e "-------- \033[31m ALERT: SPECS IS EMPTY. Nothing to build \033[0m --------"
    fi
}

# enable custom-repo.repo to install RPMs from
setup_custom_repofile() {
    echo "------------ Setting up custom repofile ------------"
    
    # get default value of PACKAGE_URL_LIST from Mariner Makefile
    pushd $MARINER_BASE_DIR/toolkit 
    PACKAGE_URL_LIST=$(make printvar-PACKAGE_URL_LIST 2>/dev/null)
    popd

    for repo_file in $RPM_repo_file
    do
        # append baseurl from $repo_file to $PACKAGE_LIST_URL to use them for downloading toolchain RPMs
        PACKAGE_URL_LIST+=" "
        PACKAGE_URL_LIST+=$(cat $repo_file | grep baseurl | cut -d '=' -f 2)
        # append $repo_file to $REPO_LIST so it can be used as an upstream repo for package building
        REPO_LIST+=" "
        REPO_LIST+=$repo_file
    done
    export PACKAGE_URL_LIST
    export REPO_LIST
}

# enable custom blob storage to install RPMs from
setup_custom_repo_storage() {
    echo "------------ Downloading RPMs from custom RPM blob storage container ------------"
    # install azcopy
    wget -O azcopy_v10.tar.gz https://aka.ms/downloadazcopy-v10-linux  || { echo "ERROR: Could not install azcopy"; exit 1; }
    tar -xf azcopy_v10.tar.gz --strip-components=1
    mv azcopy /bin/
    rm -rf azcopy* NOTICE.txt

    # get architecture of the machine this container is running on
    arch=$(uname -m)
    for container_URL in $RPM_container_URL
    do
        #download all RPMs from $container_URL to use in package building
        azcopy copy $container_URL/* $MARINER_BASE_DIR/build/rpm_cache/cache
        #download all RPMs from $container_URL to use for toolchain
        azcopy copy $container_URL/* $MARINER_BASE_DIR/build/toolchain_rpms/noarch
        azcopy copy $container_URL/* $MARINER_BASE_DIR/build/toolchain_rpms/$arch
    done
}

# disable default Mariner RPM repos
disable_mariner_default_repos() {
    echo "------------ Removing Mariner default repos ------------"
    DISABLE_DEFAULT_REPOS="y"
    export DISABLE_DEFAULT_REPOS
}

# create chroot lock
pushd $CHROOT_DIR
touch chroot-pool.lock
CHROOT_NB=$(find . -maxdepth 1 -type d -name "docker-chroot-*" | wc -l)
CONCURRENT_PACKAGE_BUILDS=$CHROOT_NB
popd

# export build variables
export BUILD_DIR
export CBL_MARINER_GIT_URL
export CCACHE_DIR
export CHROOT_BASE_DIR
export CHROOT_DIR
export CHROOT_NB
export CONCURRENT_PACKAGE_BUILDS
export DISABLE_UPSTREAM_REPOS
export IMAGE_CONFIG_DIR
export LOG_LEVEL
export LOG_PUBLISH_DIR
export MARINER_BASE_DIR
export MARINER_RELEASE_TAG
export OUT_DIR
export RUN_CHECK
export SOURCE_URL
export SPECS_DIR
export USE_CCACHE

# install prerequisites
#----------------------
echo "------------ Installing Build Prerequisites ------------"

tdnf -y install \
        binutils \
        bison \
        ca-certificates \
        cdrkit \
        curl \
        dracut \
        dnf \
        dnf-utils \
        dosfstools \
        gawk \
        gcc \
        git \
        glibc-devel \
        golang \
        kernel-headers \
        lvm2 \
        make \
        parted \
        pigz \
        python3 \
        qemu-img \
        rpm \
        rpm-build \
        rsync \
        tdnf-plugin-repogpgcheck \
        tar \
        wget

go version

# clone toolkit from github and set up for Mariner build
pushd $MARINER_BASE_DIR
download_mariner_toolkit
popd

# enable custom repo from file if true
if [[ "${enable_custom_repofile}" == "true" ]]; then setup_custom_repofile; fi

# enable custom repo from storage if true
if [[ "${enable_custom_repo_storage}" == "true" ]]; then setup_custom_repo_storage; fi

# disable Mariner repos if true
if [[ "${disable_mariner_repo}" == "true" ]]; then disable_mariner_default_repos; fi

# check if $SPECS_DIR is empty
check_specs

cd /mariner/toolkit/ || { echo "ERROR: Could not change directory to /mariner/toolkit/"; exit 1; }
