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
SDIMAGE_ZIP="/data/sdimage.img.zip"
ROOTFS_TAR="rootfs-arm64.tar.gz"

# Cleanup
mkdir -p /data
rm -fr "${SDIMAGE_DIR}"

# Create image
mkdir -p "${SDIMAGE_DIR}"
pushd "${SDIMAGE_DIR}"
echo "sd-image" > image-release.txt
popd

# Tell Linux how to start binaries that need emulation to use Qemu
update-binfmts --enable qemu-${QEMU_ARCH}

# Import basic rootfs
pushd /data
if [ ! -f "${ROOTFS_TAR}" ]; then
  wget -q https://github.com/hypriot/os-rootfs/releases/download/v0.4/${ROOTFS_TAR}
fi
popd
# Unpack basic rootfs
tar -xzf "/data/${ROOTFS_TAR}" -C "${SDIMAGE_DIR}/"
# Determine SD card image size
du -sh "${SDIMAGE_DIR}/"

echo "HYPRIOT_DEVICE=\"${HYPRIOT_DEVICE}\"" | chroot "${SDIMAGE_DIR}/" \
  tee -a /etc/os-release

# Package rootfs tarball
umask 0000
tar -czf "${SDIMAGE_ZIP}" -C "${SDIMAGE_DIR}/" .

# Test if rootfs is OK
/test.sh
