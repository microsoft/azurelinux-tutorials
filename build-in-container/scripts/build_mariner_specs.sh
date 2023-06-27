#!/bin/bash

set -e
set -x
SRC_ROOT=/sources
BUILD_ARTIFACTS_FOLDER_NAME="DockerStage"
BUILD_OUT_BASE_DIR="/tmp/mariner"
CHROOT_BASE_DIR="/temp/DockerStage"
PREREQ_INSTALL="true"
VERBOSE=0
CHROOT_NB=${CHROOT_NB:=0}

mkdir -p $SRC_ROOT/out/RPMS/noarch
mkdir -p $SRC_ROOT/out/RPMS/aarch64
mkdir -p $SRC_ROOT/out/RPMS/x86_64
mkdir -p $SRC_ROOT/build/rpm_cache/cache
mkdir -p $SRC_ROOT/ccache

pushd /sources/scripts

source "pipeline_setup.sh"

source "build.sh" \
    -a "$BUILD_ARTIFACTS_FOLDER_NAME" \
    -c "$CHROOT_BASE_DIR" \
    -o "$BUILD_OUT_BASE_DIR" \
    -n "$CHROOT_NB"
