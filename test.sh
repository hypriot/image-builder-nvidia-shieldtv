#!/bin/bash -e
set +x
# This script should be run inside of a Docker container only
if [ ! -f /.dockerinit ]; then
  echo "ERROR: script works in Docker only!"
  exit 1
fi

# Build SD card image
SDIMAGE_DIR="/sdimage"
SDIMAGE_ZIP="/data/sdimage.img.zip"

# Cleanup
echo "Testing: SDIMAGE_ZIP=${SDIMAGE_ZIP}"
mkdir -p /data
if [ ! -d "${SDIMAGE_DIR}" ]; then
  mkdir -p "${SDIMAGE_DIR}"
  if [ ! -f "${SDIMAGE_ZIP}" ]; then
    echo "ERROR: SD card image zipfile ${SDIMAGE_ZIP} missing!"
    exit 1
  fi
  tar -xzf "${SDIMAGE_ZIP}" -C "${SDIMAGE_DIR}/"
fi

# Test if rootfs is OK
cd "${SDIMAGE_DIR}" && rspec /test
