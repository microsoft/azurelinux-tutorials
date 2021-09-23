#!/bin/bash

echo "################Starting Postinstall####################"

SCRIPT_FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "PWD           -> $PWD"
echo "SCRIPT_FOLDER -> $SCRIPT_FOLDER"
echo "--------------------------------------------------------"
ls -lRa $SCRIPT_FOLDER/..
echo "--------------------------------------------------------"


# sudo tdnf install openssh

# # Enable Open-SSH server
# sudo systemctl enable sshd
# sudo systemctl start sshd

echo "###################Finish Postinstall ###################"