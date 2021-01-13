#! /bin/bash

echo -e "Fix" | parted /dev/mmcblk0 ---pretend-input-tty unit % resizepart 2
echo -e "yes\n100%" | parted /dev/mmcblk0 ---pretend-input-tty unit % resizepart 2
partprobe
resize2fs /dev/mmcblk0p2

touch /var/rootfsresized
sync