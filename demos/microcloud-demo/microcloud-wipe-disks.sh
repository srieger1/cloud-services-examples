#!/bin/bash
# does not clean everything - strangely
#sudo wipefs -a /dev/sda
#sudo wipefs -a /dev/sdb
#sudo dd if=/dev/zero of=/dev/sda bs=1M count=10
#sudo dd if=/dev/zero of=/dev/sdb bs=1M count=10
sudo partprobe
lsblk
