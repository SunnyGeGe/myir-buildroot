#!/bin/sh
# post-image.sh for MYD-C335X
# 2016, Sunny Guo <sunny.guo@myirtech.com>

export MTOOLS_SKIP_CHECK=1
BOARD_DIR="$(dirname $0)"

# copy the uEnv.txt to the output/images directory
cp board/myir/myd_c335x/uEnv.txt $BINARIES_DIR/uEnv.txt
cp board/myir/myd_c335x/uEnv_sd.txt $BINARIES_DIR/uEnv_sd.txt
cp board/myir/myd_c335x/uEnv_sd_ramdisk.txt $BINARIES_DIR/uEnv_sd_ramdisk.txt
cp board/myir/myd_c335x/uEnv_mmc.txt $BINARIES_DIR/uEnv_mmc.txt
cp board/myir/myd_c335x/uEnv_usbmsc.txt $BINARIES_DIR/uEnv_usbmsc.txt
cp board/myir/myd_c335x/uEnv_ramdisk.txt $BINARIES_DIR/uEnv_ramdisk.txt
cp board/myir/myd_c335x/uEnv_usbmsc_ramdisk.txt $BINARIES_DIR/uEnv_usbmsc_ramdisk.txt
#cp board/myir/myd_c335x/MLO $BINARIES_DIR/MLO
cp board/myir/myd_c335x/MLO_emmc $BINARIES_DIR/MLO_emmc
cp board/myir/myd_c335x/MLO_nand $BINARIES_DIR/MLO_nand
cp board/myir/myd_c335x/MLO_sd $BINARIES_DIR/MLO_sd
cp board/myir/myd_c335x/MLO_usbmsc $BINARIES_DIR/MLO_usbmsc
#cp board/myir/myd_c335x/u-boot.img $BINARIES_DIR/u-boot.img
cp board/myir/myd_c335x/u-boot_sd.img $BINARIES_DIR/u-boot_sd.img
cp board/myir/myd_c335x/u-boot_emmc.img $BINARIES_DIR/u-boot_emmc.img
cp board/myir/myd_c335x/u-boot_nand.img $BINARIES_DIR/u-boot_nand.img
cp board/myir/myd_c335x/u-boot_usbmsc.img $BINARIES_DIR/u-boot_usbmsc.img
cp board/myir/myd_c335x/readme.txt $BINARIES_DIR/readme.txt
mkimage -A arm -O linux -T ramdisk -C none -a 0x88080000 -n "ramdisk" -d $BINARIES_DIR/rootfs.cpio.gz $BINARIES_DIR/ramdisk.gz

cp board/myir/myd_c335x/kernel.its $BINARIES_DIR/kernel.its
cp board/myir/myd_c335x/recovery.its $BINARIES_DIR/recovery.its
mkimage -f  $BINARIES_DIR/kernel.its $BINARIES_DIR/kernel.img
mkimage -f  $BINARIES_DIR/recovery.its $BINARIES_DIR/recovery.img

cp board/myir/myd_c335x/update.sh $BINARIES_DIR/update.sh
cp board/myir/myd_c335x/sw-description $BINARIES_DIR/sw-description
cp board/myir/myd_c335x/generate_swu.sh $BINARIES_DIR/generate_swu.sh


GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

rm -rf "${GENIMAGE_TMP}"

genimage \
    --rootpath "${TARGET_DIR}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${BINARIES_DIR}" \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_CFG}"

cd $BINARIES_DIR
source $BINARIES_DIR/generate_swu.sh
