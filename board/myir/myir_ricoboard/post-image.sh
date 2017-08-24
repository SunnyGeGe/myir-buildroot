#!/bin/sh
# post-image.sh for MYIR RICOBOARD
# 2016, Sunny.Guo <sunny.guo@myirtech.com>

BOARD_DIR="$(dirname $0)"

# copy the uEnv.txt to the output/images directory
mkdir -p $BINARIES_DIR/uEnv
cp board/myir/myir_ricoboard/uEnv.txt $BINARIES_DIR/uEnv.txt
cp board/myir/myir_ricoboard/uEnv_hdmi.txt $BINARIES_DIR/uEnv_hdmi.txt
cp board/myir/myir_ricoboard/uEnv_mmc.txt $BINARIES_DIR/uEnv_mmc.txt
cp board/myir/myir_ricoboard/uEnv_ramdisk.txt $BINARIES_DIR/uEnv_ramdisk.txt
cp board/myir/myir_ricoboard/uEnv.txt $BINARIES_DIR/uEnv/uEnv.txt
cp board/myir/myir_ricoboard/uEnv_hdmi.txt $BINARIES_DIR/uEnv/uEnv_hdmi.txt
cp board/myir/myir_ricoboard/uEnv_mmc.txt $BINARIES_DIR/uEnv/uEnv_mmc.txt
cp board/myir/myir_ricoboard/uEnv_ramdisk.txt $BINARIES_DIR/uEnv/uEnv_ramdisk.txt
cp board/myir/myir_ricoboard/readme.txt $BINARIES_DIR/readme.txt
mkimage -A arm -O linux -T ramdisk -C none -a 0x88080000 -n "ramdisk" -d $BINARIES_DIR/rootfs.cpio.gz $BINARIES_DIR/ramdisk.gz

cp board/myir/myir_ricoboard/tisdk-rootfs-image-am437x-evm.tar.gz $BINARIES_DIR/matrix-rootfs.tar.gz

tar xvf $BINARIES_DIR/matrix-rootfs.tar.gz ./lib/modules/4.1.18-gbbe8cfc
tar xvf $BINARIES_DIR/rootfs.tar ./lib/modules/4.1.18
cp  ./lib/modules/4.1.18-gbbe8cfc/extra ./lib/modules/4.1.18 -rf
rm ./lib/modules/4.1.18/extra/omapdrm_pvr.ko
sed -i '/omapdrm_pvr/d' ./lib/modules/4.1.18/modules.dep
sed -i '$a\extra/pvrsrvkm.ko:' ./lib/modules/4.1.18/modules.dep
sed -i '$a\extra/bc_example.ko: extra/pvrsrvkm.ko' ./lib/modules/4.1.18/modules.dep
sed -i '$a\extra/cryptodev.ko:' ./lib/modules/4.1.18/modules.dep
gzip -d $BINARIES_DIR/matrix-rootfs.tar.gz
tar rvf $BINARIES_DIR/matrix-rootfs.tar ./lib/modules/4.1.18
gzip -9 -c $BINARIES_DIR/matrix-rootfs.tar  > $BINARIES_DIR//matrix-rootfs.tar.gz
rm -rf ./lib/modules/4.1.18

GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

rm -rf "${GENIMAGE_TMP}"

genimage \
    --rootpath "${TARGET_DIR}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${BINARIES_DIR}" \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_CFG}"
