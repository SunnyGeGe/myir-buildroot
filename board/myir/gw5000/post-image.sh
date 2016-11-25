#!/bin/sh
# post-image.sh for MYD-AM335X
# 2016, Dustin Guo <dustin.guo.sz@qq.com>

BOARD_DIR="$(dirname $0)"

# copy the uEnv.txt to the output/images directory
#cp board/myir/uEnv.txt $BINARIES_DIR/uEnv.txt

GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

rm -rf "${GENIMAGE_TMP}"

genimage \
    --rootpath "${TARGET_DIR}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${BINARIES_DIR}" \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_CFG}"
