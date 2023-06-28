#!/bin/bash
set -euo pipefail

SOURCE_FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

CBL_MARINER_GIT_URL="https://github.com/microsoft/CBL-Mariner.git"

VERBOSE=1
LOG_LEVEL=info
CCACHE_DIR=$BUILD_OUT_BASE_DIR/ccache
SPECS_DIR=$SOURCE_FOLDER/SPECS
USE_CCACHE="y"
ARTIFACT_PUBLISH_DIR=""
LOG_PUBLISH_DIR=""
ERRORS_OCCURRED=0

readonly MARINER_RELEASE_TAG="2.0-stable"

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

function download_mariner_toolkit() {
    if [ ! -d toolkit ]; then
        if [ ! -d CBL-Mariner ]; then
            log " -- Clone CBL-Mariner toolkit from github"
            git clone \
                --branch ${MARINER_RELEASE_TAG} \
                --depth 1 \
                ${CBL_MARINER_GIT_URL}
        fi
        log " -- Build CBL-Mariner toolkit"
        sudo make \
            -C CBL-Mariner/toolkit \
            package-toolkit \
            BUILD_DIR="$BUILD_DIR" \
            CHROOT_DIR="$CHROOT_BASE_DIR" \
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
# Global variables expected to be defined: BUILD_DIR, CCACHE_DIR, CHROOT_BASE_DIR, CHROOT_NB, LOG_LEVEL, OUT_DIR, SPECS_DIR
build_specs() {
    sudo make -C toolkit build-packages \
        CONFIG_FILE="" \
        REBUILD_TOOLS=y \
        SPECS_DIR="$SPECS_DIR" \
        CHROOT_DIR="$CHROOT_BASE_DIR" \
        CONCURRENT_PACKAGE_BUILDS="$CHROOT_NB" \
        BUILD_DIR="$BUILD_DIR" \
        CCACHE_DIR="$CCACHE_DIR" \
        OUT_DIR="$OUT_DIR" \
        LOG_LEVEL="$LOG_LEVEL" \
        REPO_LIST="repos/mariner-extended.repo" #temporary for dependency packages
}

# Package build artifacts and place in build artifact publishing directory
# This overwrites packaged artifacts from previous calls to this function
# The SRPMs and RPMs from previous calls are preserved and packaged as long as
#  `make clean` has not been called between builds of separate repos
#
# No arguments
# Global variables expected to be defined: BUILD_DIR, OUT_DIR, $ARTIFACT_PUBLISH_DIR
publish_build_artifacts() {
    log "-- pack built RPMs and SRPMs"
    sudo make -C CBL-Mariner/toolkit compress-srpms compress-rpms \
        BUILD_DIR="$BUILD_DIR" \
        OUT_DIR="$OUT_DIR"

    log "-- pack built RPMs and SRPMs"
    mkdir -p "$ARTIFACT_PUBLISH_DIR"
    sudo mv "$OUT_DIR/srpms.tar.gz" "$ARTIFACT_PUBLISH_DIR"
    sudo mv "$OUT_DIR/rpms.tar.gz" "$ARTIFACT_PUBLISH_DIR"
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

echo "============================"
echo "Building overlake-packages  "
echo "============================"

# parse script parameters:
#
# -a -> build artifacts folder name
# -c -> chroot base dir
# -o -> root folder for out and build dir
# -p -> folder where built RPMs/SRPMs should be published
# -n -> nb of chroots (this will be used to parallelize the build, 0 means as many as machine supports)
# -d -> enable development mode (ccache, etc).

while getopts ":a:c:o:p:q:n:dv" OPTIONS; do
  case "${OPTIONS}" in
    a ) BUILD_ARTIFACTS_FOLDER_NAME=$OPTARG ;;
    c ) CHROOT_BASE_DIR=$OPTARG ;;
    o ) BUILD_OUT_BASE_DIR=$OPTARG
        BUILD_DIR=$BUILD_OUT_BASE_DIR/build
        CCACHE_DIR=$BUILD_OUT_BASE_DIR/ccache
        OUT_DIR=$BUILD_OUT_BASE_DIR/out ;;
    p ) ARTIFACT_PUBLISH_DIR=$OPTARG ;;
    q ) LOG_PUBLISH_DIR=$OPTARG ;;
    n ) CHROOT_NB=$OPTARG ;;
    d ) USE_CCACHE=y ;;
    v ) VERBOSE=1
        if [[ "$LOG_LEVEL" == "info" ]]; then
            LOG_LEVEL="debug"
        else
            LOG_LEVEL="info"
        fi
        set -x ;;
    \? )
        echo "Error - Invalid Option: -$OPTARG" 1>&2
        exit 1
        ;;
    : )
        echo "Error - Invalid Option: -$OPTARG requires an argument" 1>&2
        exit 1
        ;;
  esac
done

echo "-- BUILD_ARTIFACTS_FOLDER_NAME        -> $BUILD_ARTIFACTS_FOLDER_NAME"
echo "-- BUILD_OUT_BASE_DIR                 -> $BUILD_OUT_BASE_DIR"
echo "-- BUILD_DIR                          -> $BUILD_DIR"
echo "-- OUT_DIR                            -> $OUT_DIR"
echo "-- CHROOT_BASE_DIR                    -> $CHROOT_BASE_DIR"
echo "-- CHROOT_NB (0 = max)                -> $CHROOT_NB"
echo "-- ARTIFACT_PUBLISH_DIR               -> $ARTIFACT_PUBLISH_DIR"
echo "-- LOG_PUBLISH_DIR                    -> $LOG_PUBLISH_DIR"
echo "-- USE_CCACHE                         -> $USE_CCACHE"
echo ""

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

log "-- Build core specs"
build_specs SPECS

if [[ -n $ARTIFACT_PUBLISH_DIR ]]; then
    log "-- Publish build artifacts"
    publish_build_artifacts
fi
