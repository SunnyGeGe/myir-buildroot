#!/bin/sh -e
export MTOOLS_SKIP_CHECK=1

if grep -Eq "^BR2_PACKAGE_MEASY_HMI=y$" ${BR2_CONFIG}; then
        echo "\"include measy_hmi\""
	cp -a board/myir/common/HMI/*  output/target
else
                echo "\" not include measy_hmi\""
fi

if [ -e ${TARGET_DIR}/lib/firmware/pru/PRU_Halt.out ]; then
	ln -sf /lib/firmware/pru/PRU_Halt.out ${TARGET_DIR}/lib/firmware/am335x-pru0-fw
	ln -sf /lib/firmware/pru/PRU_Halt.out ${TARGET_DIR}/lib/firmware/am335x-pru1-fw
fi
