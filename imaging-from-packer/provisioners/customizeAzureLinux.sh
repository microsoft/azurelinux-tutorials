#!/bin/bash

set -e

# install additional repositories from where to fetch Azure Linux packages
echo "-- install additional repositories"
echo $USER_PSW | sudo -S tdnf -y install \
    azure-linux-repos-extras

# install packages
echo "-- install required packages"
echo $USER_PSW | sudo -S tdnf -y install \
    audit \
    auoms \
    azsec-clamav \
    azsec-monitor \
    azure-security \
    clamav
