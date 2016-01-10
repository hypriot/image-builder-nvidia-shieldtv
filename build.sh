#!/bin/bash -e
set -x
# This script should be run only inside of a Docker container
if [ ! -f /.dockerinit ]; then
  echo "ERROR: script works only in a Docker container!"
  exit 1
fi

### setting up some important variables to control the build process

# where to store our created sd-image file
BUILD_RESULT="/workspace"

# where to store our base file system
ROOTFS_TAR="rootfs-arm64.tar.gz"
ROOTFS_TAR_PATH="${BUILD_RESULT}/${ROOTFS_TAR}"

# what kernel to use
KERNEL_DATETIME=${KERNEL_DATETIME:="20151103-193133"}
KERNEL_VERSION=${KERNEL_VERSION:="4.1.12"}

# building the name of our sd-card image file
IMAGE_NAME="sd-card-nvidia-shieldtv.img"

# size of root and boot partion
ROOT_PARTITION_SIZE="800M"

# download our base root file system
if [ ! -f "${ROOTFS_TAR_PATH}" ]; then
  wget -q -O ${ROOTFS_TAR_PATH} https://github.com/hypriot/os-rootfs/releases/download/v0.4/${ROOTFS_TAR}
fi

# create the image and add a single ext4 filesystem
# --- important settings for NVIDIA ShieldTV SD card
# - initialise the partion with MBR
# - use start sector 2048, this reserves 1MByte of disk space
# - don't set the partition to "bootable"
# - format the disk with ext4
# for debugging use 'set-verbose true'
#set-verbose true
guestfish <<EOF
# create new image disk
sparse /${IMAGE_NAME} ${ROOT_PARTITION_SIZE}
run
part-init /dev/sda mbr
part-add /dev/sda primary 2048 -1
part-set-bootable /dev/sda 1 false
mkfs ext4 /dev/sda1

# import base rootfs
mount /dev/sda1 /
tar-in ${ROOTFS_TAR_PATH} / compress:gzip
EOF

# log image partioning
fdisk -l /${IMAGE_NAME}

# test sd-image that we have built
rspec --format documentation --color /${BUILD_RESULT}/test

# ensure that the travis-ci user can access the sd-card image file
umask 0000

# compress image
pigz --zip -c "${IMAGE_NAME}" > "${BUILD_RESULT}/${IMAGE_NAME}.zip"
