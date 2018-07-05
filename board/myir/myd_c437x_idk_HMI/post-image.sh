#!/bin/sh
# post-image.sh for MYD-C437X-PRU
# 2016, Sunny.Guo <sunny.guo@myirtech.com>

BOARD_DIR="$(dirname $0)"

# copy the uEnv.txt to the output/images directory
mkdir -p $BINARIES_DIR/uEnv
cp board/myir/myd_c437x_idk_HMI/uEnv.txt $BINARIES_DIR/uEnv.txt
cp board/myir/myd_c437x_idk_HMI/uEnv_mmc.txt $BINARIES_DIR/uEnv_mmc.txt
cp board/myir/myd_c437x_idk_HMI/uEnv_ramdisk.txt $BINARIES_DIR/uEnv_ramdisk.txt
cp board/myir/myd_c437x_idk_HMI/uEnv.txt $BINARIES_DIR/uEnv/uEnv.txt
cp board/myir/myd_c437x_idk_HMI/uEnv_mmc.txt $BINARIES_DIR/uEnv/uEnv_mmc.txt
cp board/myir/myd_c437x_idk_HMI/uEnv_ramdisk.txt $BINARIES_DIR/uEnv/uEnv_ramdisk.txt
cp board/myir/myd_c437x_idk_HMI/readme.txt $BINARIES_DIR/readme.txt
mkimage -A arm -O linux -T ramdisk -C none -a 0x88080000 -n "ramdisk" -d $BINARIES_DIR/rootfs.cpio.gz $BINARIES_DIR/ramdisk.gz


GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

rm -rf "${GENIMAGE_TMP}"

genimage \
    --rootpath "${TARGET_DIR}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${BINARIES_DIR}" \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_CFG}"
