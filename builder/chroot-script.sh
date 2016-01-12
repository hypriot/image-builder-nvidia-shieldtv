#!/bin/bash -e
set -x

# device specific settings
HYPRIOT_DEVICE="NVIDIA ShieldTV"
HYPRIOT_GROUPNAME="docker"
HYPRIOT_USERNAME="pirate"
HYPRIOT_PASSWORD="hypriot"

# set up /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf

apt-get update

#FIXME: has to be moved to hypriot/os-rootfs
# install parted (for online disk resizing)
apt-get install -y parted

#FIXME: has to be moved to hypriot/os-rootfs
# install sudo (for our default user)
apt-get install -y sudo

# install Hypriot group and user
addgroup --system --quiet $HYPRIOT_GROUPNAME
useradd -m $HYPRIOT_USERNAME --group $HYPRIOT_GROUPNAME --shell /bin/bash
echo "$HYPRIOT_USERNAME:$HYPRIOT_PASSWORD" | /usr/sbin/chpasswd
# add user to sudoers group
echo "$HYPRIOT_USERNAME ALL=NOPASSWD: ALL" > /etc/sudoers.d/user-$HYPRIOT_USERNAME
chmod 0440 /etc/sudoers.d/user-$HYPRIOT_USERNAME

#FIXME: has to be removed in hypriot/os-rootfs
# disable SSH root login
sed -i 's|PermitRootLogin yes|PermitRootLogin without-password|g' /etc/ssh/sshd_config
# remove/disable root password
passwd -d root

# set device label
echo "HYPRIOT_DEVICE=\"$HYPRIOT_DEVICE\"" >> /etc/os-release
