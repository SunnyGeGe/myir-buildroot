#!/bin/sh

if [ $# -lt 1 ]; then
	exit 0;
fi

function get_boot_device(){
	for i in `cat /proc/cmdline`; do
		case "$i" in
			ubi.mtd=*)
				ROOT="${i#ubi.mtd=}"
				;;
		esac
	done
	KERNEL="0";
	for i in `fw_printenv kernelid`; do
		case "$i" in
			kernelid=*)
				KERNEL="${i#kernelid=}"
				;;
		esac
	done
}

function get_update_part(){
	if [ "$ROOT" = "NAND.rootfs,2048" ]; then
		UPDATE_ROOTID="1";
		UPDATE_ROOT="/dev/mtd14";
	else
		UPDATE_ROOTID="0";
		UPDATE_ROOT="/dev/mtd13";
	fi	

	if [ "$KERNEL" = "0" ]; then
		UPDATE_KERNELID="1";
		UPDATE_KERNEL="/dev/mtd11";
	else
		UPDATE_KERNELID="0";
		UPDATE_KERNEL="/dev/mtd10";
	fi
}

if [ "$1" == "preinst" ]; then
	# get current root device
	get_boot_device
	echo Booting from $ROOT

	# now get the block device to be updated
	get_update_part

	echo Updateing $UPDATE_ROOT
	ln -sf $UPDATE_ROOT	/dev/mtd_rootfs
	ln -sf $UPDATE_KERNEL	/dev/mtd_kernel
fi

if [ "$1" == "postinst" ]; then
	get_boot_device
	get_update_part
	
	echo update u-boot variable: rootfsid=$UPDATE_ROOTID
	echo update u-boot variable: kernelid=$UPDATE_KERNELID
	fw_setenv rootfsid $UPDATE_ROOTID
	fw_setenv kernelid $UPDATE_KERNELID
fi
