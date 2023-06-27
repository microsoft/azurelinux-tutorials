#!/bin/bash
set -exuo pipefail

# sanity check and initialization
#--------------------------------
#BUILD_OUT_BASE_DIR="/tmp/mariner"
CHROOT_BASE_DIR="/temp/DockerStage"
#PREREQ_INSTALL="true"

# verify mount points for chroots and create chroot lock
pushd $CHROOT_BASE_DIR
touch chroot-pool.lock
CHROOT_NB=$(find . -maxdepth 1 -type d -name "docker-chroot-*" | wc -l)
export CHROOT_NB
popd

echo "-- CHROOT_BASE_DIR                          -> $CHROOT_BASE_DIR"
echo "-- CHROOT_NB                                -> $CHROOT_NB"
echo ""

# install prerequisites
#----------------------
echo "-- Install build host prerequisites."

tdnf -y install \
        binutils \
        bison \
        cdrkit \
        curl \
        dnf \
        dnf-utils \
        dosfstools \
        gawk \
        gcc \
        git \
        glibc-devel \
        golang-1.17.13-1.cm2 \
        kernel-headers \
        make \
        parted \
        pigz \
        python3 \
        qemu-img \
        rpm \
        rpm-build \
        rsync \
        sudo \
        tar \
        wget

go version
