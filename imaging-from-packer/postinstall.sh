#!/bin/bash

echo "################Starting Postinstall####################"

# Enable and start Open-SSH server
systemctl enable sshd
systemctl start sshd

echo "###################Finish Postinstall ###################"