#!/bin/bash -e
set -x
# This script should be run inside of a Docker container only
if [ ! -f /.dockerinit ]; then
  echo "ERROR: script works in Docker only!"
  exit 1
fi

# Build SD card image
HYPRIOT_DEVICE="Nvidia ShieldTV"
QEMU_ARCH="aarch64"
WORK_DIR="/workdir"
SD_IMAGE_NAME="hypriot-nvidia-shieldtv.img"
SD_IMAGE_PATH="/workdir/${SD_IMAGE_NAME}"
SD_IMAGE_ROOTFS="/workdir/rootfs"
SD_IMAGE_ZIP="/data/${SD_IMAGE_NAME}.zip"
ROOTFS_TAR="rootfs-arm64.tar.gz"
SD_CARD_SIZE="400" # in MByte

# Tell Linux how to start binaries that need emulation to use Qemu
update-binfmts --enable qemu-${QEMU_ARCH}

# Cleanup
mkdir -p /data
rm -fr "${WORK_DIR}"

# Create image dir
mkdir -p "${WORK_DIR}"

# Download basic rootfs
if [ ! -f "/data/${ROOTFS_TAR}" ]; then
  wget -q https://github.com/hypriot/os-rootfs/releases/download/v0.4/${ROOTFS_TAR} -O "/data/${ROOTFS_TAR}"
fi

# Create empty ROOTFS image file
# - SD_CARD_SIZE in MByte
# - DD uses 256 Bytes
# - sector block size is 512Bytes
# - MBR size is 512 Bytes, so we start at sector 2048 (1MByte reserved space)
ROOTFS_START=2048
SD_MINUS_DD=$(expr ${SD_CARD_SIZE} \* 1000000 - 256)
ROOTFS_SIZE=$(expr ${SD_MINUS_DD} / 512 - ${ROOTFS_START})

#++++
# create image file with 0's
dd if=/dev/zero of=${SD_IMAGE_PATH} bs=1MB count=${SD_CARD_SIZE}
# create loopback device
DEVICE=$(losetup -f --show ${SD_IMAGE_PATH})
echo "Image ${SD_IMAGE_PATH} created and mounted as ${DEVICE}."
# create partions
sfdisk --force ${DEVICE} <<PARTITION
unit: sectors
/dev/loop0p1 : start= ${ROOTFS_START}, size= ${ROOTFS_SIZE}, Id=83
/dev/loop0p2 : start= 0, size= 0, Id= 0
/dev/loop0p3 : start= 0, size= 0, Id= 0
/dev/loop0p4 : start= 0, size= 0, Id= 0
PARTITION

# detach loopback device
losetup -d $DEVICE
losetup -a
# check partitions
fdisk -l ${SD_IMAGE_PATH}
#---

#+++
# format image file
DEVICE=`kpartx -va ${SD_IMAGE_PATH} | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
# details see: https://github.com/NaohiroTamura/diskimage-builder/blob/master/elements/vm/block-device.d/10-partition#L39-L43
dmsetup --noudevsync mknodes
ROOT_PARTITION="/dev/mapper/${DEVICE}p1"
DEVICE="/dev/${DEVICE}"

# Give some time to system to refresh
#sleep 3

# create file system
mkfs.ext4 ${ROOT_PARTITION} -L root -i 4096 # create 1 inode per 4kByte block (maximum ratio is 1 per 1kByte)

# mount file system
mkdir -p ${SD_IMAGE_ROOTFS}
mount ${ROOT_PARTITION} ${SD_IMAGE_ROOTFS}
df -lh

#---xxx---
# unpack basic rootfs
tar -xzf "/data/${ROOTFS_TAR}" -C "${SD_IMAGE_ROOTFS}/"

# modify file system
pushd "${SD_IMAGE_ROOTFS}"

echo "sd-card-image" > ./image-release.txt

mkdir -p "${SD_IMAGE_ROOTFS}/etc"
echo "HYPRIOT_DEVICE=\"${HYPRIOT_DEVICE}\"" >> ./etc/os-release

# determine SD card image size
df -lh

popd
#---xxx---

# unmount file system
umount ${SD_IMAGE_ROOTFS}
# remove /dev/mapper device
#kpartx -vds ${SD_IMAGE_PATH} || true
#sleep 5
kpartx -vds ${SD_IMAGE_PATH}

# Check loopback devices
losetup -a
#---


# Package and compress SD image file
umask 0000
pigz --zip -c "${SD_IMAGE_PATH}" > "${SD_IMAGE_ZIP}"

# Test if SD image file is OK
/test.sh
