#!/bin/bash
set -euo

CBL_MARINER_GIT_URL="https://github.com/microsoft/CBL-Mariner.git"
readonly MARINER_RELEASE_TAG="2.0-stable"

VERBOSE=1
USE_CCACHE="y"
LOG_PUBLISH_DIR="/tmp/mariner/logs"

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

# Build Mariner toolkit if not present, by cloning Mariner GitHub repo
#
# No arguments
# Global variables expected to be defined: BUILD_DIR, CHROOT_DIR, CHROOT_NB, OUT_DIR
download_mariner_toolkit() {
    if [ ! -d toolkit ]; then
        if [ ! -d CBL-Mariner ]; then
            log " -- Clone CBL-Mariner toolkit from github"
            git clone \
                --branch ${MARINER_RELEASE_TAG} \
                --depth 1 \
                ${CBL_MARINER_GIT_URL}
        fi
        log " -- Build CBL-Mariner toolkit"
        sudo make -j$(nproc) \
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

# Build a list of specs in a spec folder with a list of remote repos
# Expects toolchain and worker chroot to be present before being called.
#
# No arguments
# Global variables expected to be defined: BUILD_DIR, CCACHE_DIR, CHROOT_DIR, CHROOT_NB, LOG_LEVEL, OUT_DIR, SPECS_DIR
build_specs() {
    sudo make -j$(nproc) -C toolkit build-packages \
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
    configfiles=$(ls $IMAGE_CONFIG_DIR/| grep json)
    for config_file in $configfiles
    do
        sudo make -j$(nproc) -C toolkit image \
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

trap cleanup EXIT

echo "-- BUILD_DIR                          -> $BUILD_DIR"
echo "-- OUT_DIR                            -> $OUT_DIR"
echo "-- CHROOT_DIR                         -> $CHROOT_DIR"
echo "-- CHROOT_NB (0 = max)                -> $CHROOT_NB"
echo "-- LOG_PUBLISH_DIR                    -> $LOG_PUBLISH_DIR"
echo "-- USE_CCACHE                         -> $USE_CCACHE"
echo "-- SPECS_DIR                          -> $SPECS_DIR"
echo ""

pushd /sources/scripts/

echo "------------ Setting up Mariner Toolkit ------------"
download_mariner_toolkit

if [[ "${USE_CCACHE}"=="y" ]]; then
    log "-- Apply workaround for ccache"
    # WORKAROUND: The Mariner toolkit is having trouble downloading the ccache
    # RPM in our container-based build environment; let's pre-download it.
    if compgen -G "${OUT_DIR}/RPMS/$(uname -p)/ccache-*.rpm" > /dev/null; then
        echo "ccache RPM already exists; using cached copy."
    else
        log "Downloading ccache RPM..."
        sudo mkdir -p "${OUT_DIR}/RPMS/$(uname -p)"
        sudo dnf download -y ccache --destdir out/RPMS/$(uname -p)
    fi
fi

echo "------------ Building Specs in Mariner ------------"
log "-- Build core specs"
build_specs


echo "------------ Building Images in Mariner ------------"
log "-- Build images"
build_images

echo "------------ Publishing Logs ------------"
log "-- Publish build logs"
publish_build_logs

popd
