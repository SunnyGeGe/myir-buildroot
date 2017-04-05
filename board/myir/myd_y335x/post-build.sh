#!/bin/sh -e

if [ -e ${TARGET_DIR}/lib/firmware/pru/PRU_Halt.out ]; then
	ln -sf /lib/firmware/pru/PRU_Halt.out ${TARGET_DIR}/lib/firmware/am335x-pru0-fw
	ln -sf /lib/firmware/pru/PRU_Halt.out ${TARGET_DIR}/lib/firmware/am335x-pru1-fw
fi
