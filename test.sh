#!/bin/bash -e
set +x
# This script should be run inside of a Docker container only
if [ ! -f /.dockerinit ]; then
  echo "ERROR: script works in Docker only!"
  exit 1
fi

# Test SD card image
HYPRIOT_DEVICE="Nvidia ShieldTV"
QEMU_ARCH="aarch64"
WORK_DIR="/workdir"
SD_IMAGE_NAME="hypriot-nvidia-shieldtv.img"
SD_IMAGE_PATH="/workdir/${SD_IMAGE_NAME}"
SD_IMAGE_ROOTFS="/workdir/rootfs"
SD_IMAGE_ZIP="/data/${SD_IMAGE_NAME}.zip"

# Attach SD card image
echo ""
echo "Testing: SD_IMAGE_ZIP=${SD_IMAGE_ZIP}"
mkdir -p /data
if [ ! -d "${WORK_DIR}" ]; then
  mkdir -p "${WORK_DIR}"
fi
if [ ! -f "${SD_IMAGE_PATH}" ]; then	
  if [ ! -f "${SD_IMAGE_ZIP}" ]; then
    echo "ERROR: SD card image zipfile ${SD_IMAGE_ZIP} missing!"
    exit 1
  fi
  pigz -d -c "${SD_IMAGE_ZIP}" > "${SD_IMAGE_PATH}"
fi
ls -al "${SD_IMAGE_PATH}"


#---
# create loopback device
DEVICE=`kpartx -va ${SD_IMAGE_PATH} | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
dmsetup --noudevsync mknodes
ROOT_PARTITION="/dev/mapper/${DEVICE}p1"

# mount file system
mkdir -p ${SD_IMAGE_ROOTFS}
mount ${ROOT_PARTITION} ${SD_IMAGE_ROOTFS}
df -lh

#---xxx---
# Test if rootfs is OK
pushd "${SD_IMAGE_ROOTFS}"
rspec /test
popd
#---xxx---

# unmount file system
umount ${SD_IMAGE_ROOTFS}
# remove /dev/mapper device
#kpartx -vds ${SD_IMAGE_PATH} || true
#sleep 5
kpartx -vds ${SD_IMAGE_PATH}

# check loopback devices
losetup -a
#---
