#!/bin/bash -e
set -x

# device specific settings
HYPRIOT_DEVICE="NVIDIA ShieldTV"

# set up /etc/resolv.conf
DEST=$(readlink -m /etc/resolv.conf)
mkdir -p "$(dirname "${DEST}")"
echo "nameserver 8.8.8.8" > "${DEST}"

# install parted (for online disk resizing)
apt-get update
apt-get install -y parted

# set device label
echo "HYPRIOT_DEVICE=\"${HYPRIOT_DEVICE}\"" >> /etc/os-release
