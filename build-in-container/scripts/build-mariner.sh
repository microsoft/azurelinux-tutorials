#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

set -e
set -x

# parse args passed to container
args=("$@")
for ((i = 0; i < ${#args[@]}; i=i+2)); do
    if [[ ${args[$i]} = "container_type" ]]; then
        container_type=${args[$i+1]}
    fi
    if [[ ${args[$i]} = "RPM_repo" ]]; then
        RPM_repo=${args[$i+1]}
    fi
    if [[ ${args[$i]} = "RPM_storage" ]]; then
        RPM_storage=${args[$i+1]}
    fi
    if [[ ${args[$i]} = "enable_custom_repo" ]]; then
        enable_custom_repo=${args[$i+1]}
    fi
    if [[ ${args[$i]} = "disable_mariner_repo" ]]; then
        disable_mariner_repo=${args[$i+1]}
    fi
done

source /mariner/scripts/setup.sh

if [[ "${container_type}" == "build" ]]; then
    # exit if SPECS/ is empty
    if [ ! "$(ls -A $SPECS_DIR)" ]; then exit; fi
    source /mariner/scripts/build.sh
else
    /bin/bash
fi
