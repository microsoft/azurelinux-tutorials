#! /bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

set -e

docker build -t 'mcr.microsoft.com/mariner-container-build:2.0' ${tool_dir}
