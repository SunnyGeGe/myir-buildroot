#!/bin/bash

CONTAINER_VER="1.0"
PRODUCT_NAME="myd-c335x"
FILES="sw-description rootfs.ubi kernel.img update.sh"

#openssl dgst -sha256 -sign swupdate-priv.pem sw-description > sw-description.sig

for i in $FILES;do
        echo $i;done | cpio -ov -H crc >  ${PRODUCT_NAME}_${CONTAINER_VER}.swu
