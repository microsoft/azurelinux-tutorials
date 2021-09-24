#!/bin/bash

# install packages
echo "-- install required packages"
echo $USER_PSW | sudo -S tdnf -y install \
     audit \
     auoms \
    azsec-clamav \
    azsec-monitor \
    azure-security \
    clamav