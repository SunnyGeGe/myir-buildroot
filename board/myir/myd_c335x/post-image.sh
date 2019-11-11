#!/bin/sh
# post-image.sh for MYD-C335X
# 2016, Sunny Guo <sunny.guo@myirtech.com>

export MTOOLS_SKIP_CHECK=1
BOARD_DIR="$(dirname $0)"

mkimage -A arm -O linux -T ramdisk -C none -a 0x88080000 -n "ramdisk" -d $BINARIES_DIR/rootfs.cpio.gz $BINARIES_DIR/ramdisk.gz

mkdir -p $BINARIES_DIR/images > /dev/null 2>&1

if grep -Eq "^BR2_TARGET_UBOOT_BOARD_DEFCONFIG=\"myd_c335x_emmc\"$" ${BR2_CONFIG}; then
    echo "generate uEnv for emmc image................."
    cp board/myir/myd_c335x/uEnv.txt  $BINARIES_DIR/uEnv.txt
    cp $BINARIES_DIR/MLO $BINARIES_DIR/images/MLO
    cp $BINARIES_DIR/MLO $BINARIES_DIR/images/MLO_emmc
    cp $BINARIES_DIR/u-boot.img $BINARIES_DIR/images/u-boot.img
    cp $BINARIES_DIR/u-boot.img $BINARIES_DIR/images/u-boot_emmc.img
    cp board/myir/myd_c335x/u-boot_nand.img $BINARIES_DIR/images/
    cp board/myir/myd_c335x/MLO_nand $BINARIES_DIR/images/
else
    echo "generate uEnv for nand image................."
    cp board/myir/myd_c335x/uEnv.txt  $BINARIES_DIR/uEnv.txt
    cp $BINARIES_DIR/MLO $BINARIES_DIR/images/MLO
    cp $BINARIES_DIR/MLO $BINARIES_DIR/images/MLO_nand
    cp $BINARIES_DIR/u-boot.img $BINARIES_DIR/images/u-boot.img
    cp $BINARIES_DIR/u-boot.img $BINARIES_DIR/images/u-boot_nand.img
    cp board/myir/myd_c335x/u-boot_emmc.img $BINARIES_DIR/images/
    cp board/myir/myd_c335x/MLO_emmc $BINARIES_DIR/images/
fi
# copy the uEnv.txt to the output/images directory
cp board/myir/myd_c335x/uEnv_sd.txt $BINARIES_DIR/images/uEnv_sd.txt
cp board/myir/myd_c335x/uEnv_sd_ramdisk.txt $BINARIES_DIR/images/uEnv_sd_ramdisk.txt
cp board/myir/myd_c335x/uEnv_mmc.txt $BINARIES_DIR/images/uEnv_mmc.txt
cp board/myir/myd_c335x/uEnv_usbmsc.txt $BINARIES_DIR/images/uEnv_usbmsc.txt
cp board/myir/myd_c335x/uEnv_ramdisk.txt $BINARIES_DIR/images/uEnv_ramdisk.txt
cp board/myir/myd_c335x/uEnv_usbmsc_ramdisk.txt $BINARIES_DIR/images/uEnv_usbmsc_ramdisk.txt
cp $BINARIES_DIR/MLO $BINARIES_DIR/images/MLO_sd
cp $BINARIES_DIR/MLO $BINARIES_DIR/images/MLO_usbmsc
cp $BINARIES_DIR/u-boot.img $BINARIES_DIR/images/u-boot_sd.img
cp $BINARIES_DIR/u-boot.img $BINARIES_DIR/images/u-boot_usbmsc.img
cp $BINARIES_DIR/zImage $BINARIES_DIR/images/
cp $BINARIES_DIR/ramdisk.gz $BINARIES_DIR/images/
cp $BINARIES_DIR/uEnv.txt $BINARIES_DIR/images/
cp $BINARIES_DIR/myd_c335x.dtb $BINARIES_DIR/images/
cp $BINARIES_DIR/myd_c335x_emmc.dtb $BINARIES_DIR/images/
cp $BINARIES_DIR/rootfs.ubi $BINARIES_DIR/images/
cp $BINARIES_DIR/rootfs.tar.gz $BINARIES_DIR/images/
cp board/myir/myd_c335x/readme.* $BINARIES_DIR/
cp board/myir/myd_c335x/uEnv_updatesys_nand.txt  $BINARIES_DIR/
cp board/myir/myd_c335x/uEnv_updatesys_emmc.txt  $BINARIES_DIR/

cp board/myir/myd_c335x/kernel.its $BINARIES_DIR/kernel.its
cp board/myir/myd_c335x/recovery.its $BINARIES_DIR/recovery.its
mkimage -f  $BINARIES_DIR/kernel.its $BINARIES_DIR/kernel.img
mkimage -f  $BINARIES_DIR/recovery.its $BINARIES_DIR/recovery.img
cp $BINARIES_DIR/kernel.img $BINARIES_DIR/images/
cp $BINARIES_DIR/recovery.img $BINARIES_DIR/images/

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

echo ${BR2_CONFIG}

if grep -Eq "^BR2_TARGET_UBOOT_BOARD_DEFCONFIG=\"myd_c335x_emmc\"$" ${BR2_CONFIG}; then
    echo "generate uEnv for emmc image................."
    cp board/myir/myd_c335x/uEnv_emmc_ramdisk.txt  $BINARIES_DIR/uEnv.txt
else
    echo "generate uEnv for nand image................."
    cp board/myir/myd_c335x/uEnv_ramdisk.txt  $BINARIES_DIR/uEnv.txt
fi

cd $BINARIES_DIR
source $BINARIES_DIR/generate_swu.sh
