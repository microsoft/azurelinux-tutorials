#!/bin/bash

set -e

# install additional repositories from where to fetch Mariner packages
echo "-- install additional repositories"
echo $USER_PSW | sudo -S tdnf -y install \
    mariner-repos-extras

# install packages
echo "-- install required packages"
echo $USER_PSW | sudo -S tdnf -y install \
    audit \
    auoms \
    azsec-clamav \
    azsec-monitor \
    azure-security \
    clamav
