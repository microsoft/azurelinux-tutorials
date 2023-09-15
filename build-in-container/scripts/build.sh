#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

set -euo

if [ -t 1 ]; then
    CYAN="\e[36m"
    RESET="\e[0m"
else
    CYAN=""
    RESET=""
fi

function log() {
    timestamp="$(date "+%F %R:%S")"
    echo -e "${CYAN}+++ $timestamp $1${RESET}"
}

function cleanup() {
    log "Cleaning up..."
    if [[ -n $LOG_PUBLISH_DIR ]]; then
        publish_build_logs
    fi
}

# Build a list of specs in a spec folder with a list of remote repos
# Expects toolchain and worker chroot to be present before being called.
#
# No arguments
# Global variables expected to be defined: BUILD_DIR, CCACHE_DIR, CHROOT_DIR, CHROOT_NB, LOG_LEVEL, OUT_DIR, SPECS_DIR
build_specs() {
    make -j$(nproc) build-packages \
        CONFIG_FILE="" \
        REBUILD_TOOLS=y \
        SPECS_DIR="$SPECS_DIR" \
        CHROOT_DIR="$CHROOT_DIR" \
        CONCURRENT_PACKAGE_BUILDS="$CHROOT_NB" \
        BUILD_DIR="$BUILD_DIR" \
        CCACHE_DIR="$CCACHE_DIR" \
        OUT_DIR="$OUT_DIR" \
        LOG_LEVEL="$LOG_LEVEL"
}

# Build a list of images in a image config folder with a list of remote repos
# Expects toolchain and worker chroot to be present before being called.
#
# No arguments
# Global variables expected to be defined: BUILD_DIR, CCACHE_DIR, CHROOT_DIR, CHROOT_NB, LOG_LEVEL, OUT_DIR
build_images() {
    configfiles=$(ls $IMAGE_CONFIG_DIR/| grep marketplace-gen2.json)
    for config_file in $configfiles
    do
        make -j$(nproc) image \
        REBUILD_TOOLS=y \
        CONFIG_FILE="$IMAGE_CONFIG_DIR/$config_file" \
        SPECS_DIR="$SPECS_DIR" \
        REBUILD_PACKAGES=n \
        CHROOT_DIR="$CHROOT_DIR" \
        CONCURRENT_PACKAGE_BUILDS="$CHROOT_NB" \
        BUILD_DIR="$BUILD_DIR" \
        CCACHE_DIR="$CCACHE_DIR" \
        OUT_DIR="$OUT_DIR" \
        LOG_LEVEL="$LOG_LEVEL"
    done
}

# Package log artifacts and place in log artifact publishing directory
# This overwrites packaged logs from previous calls to this function
# The logs from previous calls are preserved and packaged as long as
#  `make clean` has not been called between builds of separate repos
#
# No arguments
# Global variables expected to be defined: LOG_PUBLISH_DIR, BUILD_DIR
publish_build_logs() {
    log "-- pack logs"
    mkdir -p "$LOG_PUBLISH_DIR"
    if [[ -d $BUILD_DIR/logs ]]; then
        tar -C "$BUILD_DIR/logs" -czf "$LOG_PUBLISH_DIR/pkggen.logs.tar.gz" .
    else
        echo "-- Warning - no 'logs' folder under $BUILD_DIR"
    fi
    log "-- pack package build artifacts"
    if [[ -d $BUILD_DIR/pkg_artifacts ]]; then
        tar -C "$BUILD_DIR/pkg_artifacts" -czf "$LOG_PUBLISH_DIR/pkg_artifacts.tar.gz" .
    else
        echo "-- Warning - no 'pkg_artifacts' folder under $BUILD_DIR"
    fi
}

#
# main
#

# verify that we're running inside a container, exit if not
if [[ ! -f /.dockerenv ]]; then
    echo -e "\033[31mERROR: This script must be run in a container as it uses chroot. Please use mariner-docker-builder.sh\033[0m"
    exit 1
fi
echo "------------ Verified that we are inside a docker container. Proceeding with build ------------"

trap cleanup EXIT

echo "-- BUILD_DIR                          -> $BUILD_DIR"
echo "-- OUT_DIR                            -> $OUT_DIR"
echo "-- CHROOT_DIR                         -> $CHROOT_DIR"
echo "-- CHROOT_NB (0 = max)                -> $CHROOT_NB"
echo "-- LOG_PUBLISH_DIR                    -> $LOG_PUBLISH_DIR"
echo "-- USE_CCACHE                         -> $USE_CCACHE"
echo "-- SPECS_DIR                          -> $SPECS_DIR"
echo ""

pushd $MARINER_BASE_DIR/toolkit/

echo "------------ Building Specs in Mariner ------------"
log "-- Build core specs"
build_specs

#echo "------------ Building Images in Mariner ------------"
#log "-- Build images"
#build_images

echo "------------ Publishing Logs ------------"
log "-- Publish build logs"
publish_build_logs

popd
