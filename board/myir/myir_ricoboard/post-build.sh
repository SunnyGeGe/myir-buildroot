#!/bin/sh -e
cp board/myir/myir_ricoboard/u-boot.bin ${BINARIES_DIR}/u-boot.bin
cp -a board/myir/common/HMI/*  output/target