#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

set -e
set -x

source /mariner/scripts/setup.sh

# check if SPECS/ is empty
if [ ! "$(ls -A $SPECS_DIR)" ]; then
    exit
fi
source /mariner/scripts/build.sh
