#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

set -e
set -x

# parse args passed to container
while (( "$#" )); do
    case "$1" in
        --container_type)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            container_type=$2
            shift 2
        else
            echo "Error: Argument for $1 is missing" >&2
            exit 1
        fi
        ;;
        --RPM_repo_file)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            RPM_repo_file=$2
            shift 2
        else
            echo "Error: Argument for $1 is missing" >&2
            exit 1
        fi
        ;;
        --RPM_container_URL)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            RPM_container_URL=$2
            shift 2
        else
            echo "Error: Argument for $1 is missing" >&2
            exit 1
        fi
        ;;
        --enable_custom_repofile)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            enable_custom_repofile=$2
            shift 2
        else
            echo "Error: Argument for $1 is missing" >&2
            exit 1
        fi
        ;;
        --enable_custom_repo_storage)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            enable_custom_repo_storage=$2
            shift 2
        else
            echo "Error: Argument for $1 is missing" >&2
            exit 1
        fi
        ;;
        --disable_mariner_repo)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            disable_mariner_repo=$2
            shift 2
        else
            echo "Error: Argument for $1 is missing" >&2
            exit 1
        fi
        ;;
        -*|--*=) # unsupported flags
        echo "Error: Unsupported flag $1" >&2
        exit 1
        ;;
        *) # unsupported argument
        echo "Error: Unsupported argument $1" >&2
        exit 1
        ;;
    esac
done

source /mariner/scripts/setup.sh

if [[ "${container_type}" == "build" ]]; then
    # exit if SPECS/ is empty
    if [ ! "$(ls -A $SPECS_DIR)" ]; then exit 1; fi
    source /mariner/scripts/build.sh
else
    /bin/bash
fi
