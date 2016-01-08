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
SDIMAGE_DIR="/sdimage"
SDIMAGE_PATH="/sdimage/sdimage.img"
SDIMAGE_ROOTFS="/sdimage/rootfs"
SDIMAGE_ZIP="/data/sdimage.img.zip"
SDIMAGE_GZ="/data/sdimage.img.gz"
ROOTFS_TAR="rootfs-arm64.tar.gz"
SD_CARD_SIZE="50" # in MByte

# Cleanup
mkdir -p /data
rm -fr "${SDIMAGE_DIR}"

# Create image dir
mkdir -p "${SDIMAGE_DIR}"
pushd "${SDIMAGE_DIR}"
echo "sd-image" > image-release.txt
popd

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
dd if=/dev/zero of=${SDIMAGE_PATH} bs=1MB count=${SD_CARD_SIZE}
# create loopback device
DEVICE=$(losetup -f --show ${SDIMAGE_PATH})
echo "Image ${SDIMAGE_PATH} created and mounted as ${DEVICE}."
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
fdisk -l ${SDIMAGE_PATH}
#---

#+++
# format image file
DEVICE=`kpartx -va ${SDIMAGE_PATH} | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
# details see: https://github.com/NaohiroTamura/diskimage-builder/blob/master/elements/vm/block-device.d/10-partition#L39-L43
dmsetup --noudevsync mknodes
rootp="/dev/mapper/${DEVICE}p1"
DEVICE="/dev/${DEVICE}"

# Give some time to system to refresh
#sleep 3

# create file system
mkfs.ext4 ${rootp} -L root -i 4096 # create 1 inode per 4kByte block (maximum ratio is 1 per 1kByte)

# mount file system
mkdir -p ${SDIMAGE_ROOTFS}
mount ${rootp} ${SDIMAGE_ROOTFS}
df -lh

#---xxx---
# modify file system
pushd "${SDIMAGE_ROOTFS}"
echo "sd-card-image" > image-release.txt
popd

#---xxx---

# unmount file system
umount ${SDIMAGE_ROOTFS}
# remove /dev/mapper device
#kpartx -vds ${SDIMAGE_PATH} || true
#sleep 5
kpartx -vds ${SDIMAGE_PATH}
#---


# Tell Linux how to start binaries that need emulation to use Qemu
update-binfmts --enable qemu-${QEMU_ARCH}

# Import basic rootfs
pushd /data
if [ ! -f "${ROOTFS_TAR}" ]; then
  wget -q https://github.com/hypriot/os-rootfs/releases/download/v0.4/${ROOTFS_TAR}
fi
popd
# Unpack basic rootfs
#tar -xzf "/data/${ROOTFS_TAR}" -C "${SDIMAGE_DIR}/"
# Determine SD card image size
du -sh "${SDIMAGE_DIR}/"

#echo "HYPRIOT_DEVICE=\"${HYPRIOT_DEVICE}\"" | chroot "${SDIMAGE_DIR}/" \
#  tee -a /etc/os-release
mkdir -p "${SDIMAGE_DIR}/etc"
echo "HYPRIOT_DEVICE=\"${HYPRIOT_DEVICE}\"" | tee -a "${SDIMAGE_DIR}/etc/os-release"

# Package rootfs tarball
umask 0000
tar -czf "${SDIMAGE_ZIP}" -C "${SDIMAGE_DIR}/" .
gzip -c "${SDIMAGE_PATH}" > "${SDIMAGE_GZ}"

# Test if rootfs is OK
/test.sh
