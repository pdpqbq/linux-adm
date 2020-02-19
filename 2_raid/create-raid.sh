#!/bin/bash

# create raid-6 on 5 disks
mdadm --zero-superblock --force /dev/sd{b,c,d,e,f,g,h}
mdadm --create --verbose /dev/md0 -l 6 -n 5 /dev/sd{b,c,d,e,f}
# add 2 spare disks
mdadm /dev/md0 --add /dev/sdg /dev/sdh
# create fs and mount point
mkfs.ext4 /dev/md0
mkdir /raid
echo "/dev/md0 /raid ext4 defaults 0 0" >> /etc/fstab
mount -a
# set 777 for user access
chmod 777 /raid

