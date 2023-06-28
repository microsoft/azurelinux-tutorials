#!/bin/bash
set -euo pipefail

SOURCE_FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

CBL_MARINER_GIT_URL="https://github.com/microsoft/CBL-Mariner.git"

VERBOSE=1
LOG_LEVEL=info
#BUILD_OUT_BASE_DIR=$SOURCE_FOLDER/CBL-Mariner
#BUILD_DIR=$BUILD_OUT_BASE_DIR/build
CCACHE_DIR=$BUILD_OUT_BASE_DIR/ccache
USE_CCACHE="y"
#OUT_DIR=$BUILD_OUT_BASE_DIR/out
#CHROOT_BASE_DIR="/temp/DockerStage" #$BUILD_DIR/worker/chroot
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

ensure_submodule_was_cloned() {
    local submodule_dir="$1"

    children=$(ls -A "${submodule_dir}")
    if [[ -z "${children}" ]]; then
        echo "!!!!! error: submodule not cloned: ${submodule_dir}"
        echo "!!!!! --> please make sure to run: git submodule update --init"
        exit 1
    fi
}

prepare_sources_for_spec() {
    local spec_dir="$1"
    local spec_dir_name="$(basename ${spec_dir})"
    local sources_dir="${spec_dir}/sources"

    # If there's a 'sources' subdir under the spec's dir, then let's capture
    # its contents into a well-named tarball and auto-generate a .signatures.json
    # file.
    if [[ -d "${sources_dir}" ]]; then
        local tarball_name="${spec_dir_name}.autogen.tar.gz"
        local tarball_path="${spec_dir}/${tarball_name}"
        local temp_tarball_path="$(mktemp)"

        ensure_submodule_was_cloned "${sources_dir}"

        if [[ -f "${temp_tarball_path}" ]]; then
            rm -f "${temp_tarball_path}"
        fi

        # Do our best to create a reproducible tarball whose hash will be stable.
        # Reference: https://reproducible-builds.org/docs/archives
        SOURCE_DATE_EPOCH=0
        tar \
            --format=posix \
            --sort=name \
            --mtime="@${SOURCE_DATE_EPOCH}" \
            --owner=0 \
            --group=0 \
            --numeric-owner \
            --mode=og-rwx \
            --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime,delete=mtime \
            -c -C "${spec_dir}" sources | gzip -n > "${temp_tarball_path}"
        tarball_hash=$(sha256sum ${temp_tarball_path} | cut -f1 -d" ")

        change_detected=0
        if [[ -f "${tarball_path}" ]]; then
            old_tarball_hash=$(sha256sum ${tarball_path} | cut -f1 -d" ")
            if [[ "${tarball_hash}" != "${old_tarball_hash}" ]]; then
                echo "note: re-generating tarball: ${tarball_path}"
                mv -f "${tarball_path}" "${spec_dir}/.prev.${tarball_name}"
                mv -f "${temp_tarball_path}" "${tarball_path}"
                change_detected=1
            else
                rm -f "${temp_tarball_path}"
            fi
        else
            mv -f "${temp_tarball_path}" "${tarball_path}"
            change_detected=1
        fi

        local temp_signatures_path="$(mktemp)"
        local signatures=$(echo "{}" | jq ".Signatures[\"${tarball_name}\"] = \"${tarball_hash}\"")
        for zip in ${spec_dir}/*.zip; do
            [[ -f "${zip}" ]] || continue
            local zip_hash=$(sha256sum ${zip} | cut -f1 -d" ")
            local zip_name=$(basename ${zip})
            signatures=$(echo "${signatures}" | jq ".Signatures[\"${zip_name}\"] = \"${zip_hash}\"")
        done

        # We assume that each .spec in this dir may want access to this tarball.
        for spec_path in ${spec_dir}/*.spec; do
            [[ -f "${spec_path}" ]] || continue
            local signatures_file_path="${spec_path%.*}.signatures.json"
            local existing_signatures=""
            if [[ -f "${signatures_file_path}" ]]; then
                existing_signatures=$(cat ${signatures_file_path})
            fi

            if [[ "${signatures}" != "${existing_signatures}" ]]; then
                echo "${signatures}" > "${signatures_file_path}"
            fi
        done
    fi

    # Let's check to see if there have been changes made to the spec without
    # incrementing the rev.
    HASH_SUFFIX=".v1"
    for spec_path in ${spec_dir}/*.spec; do
        [[ -f "${spec_path}" ]] || continue
        local spec_filename=$(basename "${spec_path}")
        local stem="${spec_filename%.*}"
        local signatures_file_path="${spec_dir}/${stem}.signatures.json"
        local name_and_version=$(rpmspec -q --define='with_check 0' "${spec_path}" | head -n 1)
        local name_without_rev="${name_and_version%-*}"
        local rev=${name_and_version/${name_without_rev}-/}
        rev=${rev/.src/}
        local hash_file_path="${BUILD_DIR}/spec-hashes/${name_and_version}.${HASH_SUFFIX}hash"

        files_to_hash="${spec_path}"
        if [[ -f "${signatures_file_path}" ]]; then
            files_to_hash="${signatures_file_path} ${files_to_hash}"
        fi

        mkdir -p "$(dirname "${hash_file_path}")"
        hashes=$(sha256sum $files_to_hash)
        if [[ -f "${hash_file_path}" ]]; then
            prev_hashes=$(cat "${hash_file_path}")
            if [[ "${hashes}" != "${prev_hashes}" ]]; then
                # Something changed.
                echo "!!! error: spec changed but its rev was not incremented: ${spec_path}"
                ERRORS_OCCURRED=1
            fi
        else
            echo "${hashes}" >"${hash_file_path}"
        fi

        # Check INTERMEDIATE_SRPMS, INTERMEDIATE_SPECS, out/RPMS, and out/SRPMS for stale revs and remove them.
        for find_dir in ${BUILD_DIR}/INTERMEDIATE_SRPMS ${BUILD_DIR}/INTERMEDIATE_SPECS ${OUT_DIR}/RPMS ${OUT_DIR}/SRPMS; do
            [[ -d "${find_dir}" ]] || continue
            for found_path in $(find "${find_dir}" -name "${name_without_rev}-*"); do
                local found_filename="$(basename "${found_path}")"
                local found_rev="${found_filename/${name_without_rev}-/}"
                found_rev=${found_rev/.rpm}
                found_rev=${found_rev/.src}
                found_rev=${found_rev/.noarch}
                found_rev=${found_rev/.aarch64}
                if [[ "${found_rev}" != "${rev}" ]]; then
                    echo "! warning: stale rev found at ${found_path}; stale rev=${found_rev}; current rev=${rev}"
                    echo "!   -> removing ${found_path}..."
                    rm -rf "${found_path}"
                fi
            done
        done
    done
}

prepare_sources_for_specs() {
    local specs_dir="$1"

    ERRORS_OCCURRED=0
    for spec_dir in ${specs_dir}/*; do
        prepare_sources_for_spec $spec_dir
    done

    if [[ "${ERRORS_OCCURRED}" != "0" ]]; then
        echo "!!! error: errors occurred preparing sources"
        exit 1
    fi
}

# Notes:
# - this script cannot be invoke using 'source' bash command because it needs to use its own set of parameters
#   and not to inherit the ones of its caller.
#   Consequently it cannot export variables (this script executes in its own bash context)
#   and will use 'local' files to return value to the caller (in case vso variables cannot be accessed)

# Build a list of specs in a spec folder with a list of remote repos
# Expects toolchain and worker chroot to be present before being called.
#
# Arguments:
#  $1: Path of the specs directory
# Global variables expected to be defined: CHROOT_NB, CHROOT_BASE_DIR, BUILD_DIR, OUT_DIR
build_specs() {
    local SPECS_DIR="$1"

    sudo make -C toolkit build-packages \
        CONFIG_FILE="" \
        REBUILD_TOOLS=y \
        SPECS_DIR="../../$SPECS_DIR" \
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

log "-- Prepare sources for core specs"
prepare_sources_for_specs SPECS

log "-- Build core specs"
build_specs SPECS

if [[ -n $ARTIFACT_PUBLISH_DIR ]]; then
    log "-- Publish build artifacts"
    publish_build_artifacts
fi
