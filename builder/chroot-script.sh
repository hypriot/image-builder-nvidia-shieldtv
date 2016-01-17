#!/bin/bash -e
set -x

# device specific settings
HYPRIOT_DEVICE="NVIDIA ShieldTV"

# set up /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# update all apt repository lists
export DEBIAN_FRONTEND=noninteractive
apt-get update

# set device label
echo "HYPRIOT_DEVICE=\"$HYPRIOT_DEVICE\"" >> /etc/os-release
