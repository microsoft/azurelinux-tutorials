#! /bin/bash
set -e

docker build -t 'mcr.microsoft.com/mariner-container-build:2.0' .
