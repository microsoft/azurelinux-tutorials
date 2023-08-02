#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

set -e
set -x

echo "In build-mariner.sh"
echo Your container args are: "$@"
# get args passed to container
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

echo "********* in bulid-mariner.sh**************"
echo "*** RPM_repo is $RPM_repo ***"
echo "*** RPM_storage is $RPM_storage ***"
echo "*** disable_mariner_repo is $disable_mariner_repo ***"
echo "*** enable_custom_repo is $enable_custom_repo ***"
echo "*** container_type is $container_type ***"

source /mariner/scripts/setup.sh

if [[ "${container_type}" == "build" ]]; then
    # exit if SPECS/ is empty
    if [ ! "$(ls -A $SPECS_DIR)" ]; then exit; fi
    source /mariner/scripts/build.sh
else
    /bin/bash
fi
