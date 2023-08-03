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
        -*|--*=) # unsupported flags
        echo "Error: Unsupported flag $1" >&2
        exit 1
        ;;
    esac
done

source /mariner/scripts/setup.sh

if [[ "${container_type}" == "build" ]]; then
    # exit if SPECS/ is empty
    if [ ! "$(ls -A $SPECS_DIR)" ]; then exit; fi
    source /mariner/scripts/build.sh
else
    /bin/bash
fi
