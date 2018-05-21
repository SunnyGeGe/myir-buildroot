#
# This script to update myd_c437x_evm or Rico Board system
# This script will respectively update the u-boot, device tree, zImage to
# QSPI.U_BOOT, QSPI.U-BOOT-DEVICETREE, QSPI.KERNEL, and update the filesystem
# to emmc
#
# Author: MYiR
# Email: support@myirtech.com
# Date: 2015.1.21
#	Initial Version
# Date: 2017.05.24
#	update to kernel4.1.18 and u-boot201605

#!/bin/sh

# The path sdcard mounted
SD_MOUNT_POINT="/media/mmcblk1p1"
# The rootfs partition would be mounted on current 'rootfs' directory
EMMC_BOOT_MP="boot"
EMMC_ROOTFS_MP="rootfs"

FILE_MLO="MLO"
if [ "$1" = "loader2qspi" ]; then
	FILE_UBOOT="u-boot.bin"
else
	FILE_UBOOT="u-boot.img"
fi
FILE_ZIMAGE="zImage"
FILE_DEVICETREE="myir_ricoboard.dtb"
FILE_FILESYSTEM="rootfs.tar.gz"
FILE_RAMDISK="ramdisk.gz"
FILE_UBOOTENV="u-boot-env.bin"
FILE_UENV="uEnv"
FILE_DEFAULT_UENV="uEnv/uEnv.txt"

# eMMC  is connected to mmc host 1,  sd is connected to mmc host 0
EMMC_DRIVE=

check_for_emmc()
{
	#
	# Check the eMMC was whether identified or not
	#
	if [ -d  /sys/bus/mmc/devices/mmc1:*/block/mmcblk0/ ]; then
		EMMC_DRIVE="/dev/mmcblk0"
	elif [ -d  /sys/bus/mmc/devices/mmc1:*/block/mmcblk1/ ]; then
		EMMC_DRIVE="/dev/mmcblk1"
	else
		echo -e "===> No valid emmc"
		exit 1
	fi
}

check_for_qspiflash()
{
	# Find the avaible qspi falsh
	PARTITION_TEST=`cat /proc/mtd | grep 'QSPI.'`
	if [ "$PARTITION_TEST" = "" ]; then
		echo -e "===> Not QSPI flash was found"
		if [ "$1" = "loader2qspi" ]; then
			exit 1
		fi
	fi
}

check_for_sdcards()
{
	while true; do
	SD_DRIVE=""
	# Find the avaible SD cards
	if [ -d  /sys/bus/mmc/devices/mmc0:*/block/mmcblk0/ ]; then
		SD_DRIVE="/dev/mmcblk0"
		break
	elif [ -d  /sys/bus/mmc/devices/mmc0:*/block/mmcblk1/ ]; then
		SD_DRIVE="/dev/mmcblk1"
		break
	else
		echo -e "===> Please insert a SD/TF card with update images to continue\n"
		while true; do
			busybox  sleep 1
			read -p "Type 'y' to re-detect the SD card or 'n' to exit the script: " REPLY
			if [ "$REPLY" = 'n' ]; then
				exit 1
			fi
		
		done
		
	fi
	done
	
	if [ ! -d "$SD_MOUNT_POINT" ]; then
		busybox mkdir -p $SD_MOUNT_POINT
	fi

	busybox umount $SD_MOUNT_POINT  > /dev/null 2>&1
        busybox mount -t vfat $SD_DRIVE"p1" $SD_MOUNT_POINT

}

check_files_in_sdcard()
{
	# Check MLO
	if [ "$1" != "loader2qspi" ]; then
		if [ ! -f "$SD_MOUNT_POINT/$FILE_MLO" ]; then
			echo "===> Update failed, $SD_MOUNT_POINT/$FILE_MLO not exists"
			exit 1
		fi
	fi

	# Check u-boot.bin for qspi or u-boot.img for emmc
	if [ ! -f "$SD_MOUNT_POINT/$FILE_UBOOT" ]; then
		echo "===> Update failed, $SD_MOUNT_POINT/$FILE_UBOOT not exist"
		exit 1
	fi

	# Check zImage
	if [ ! -f "$SD_MOUNT_POINT/$FILE_ZIMAGE" ]; then
		echo "===> Update failed, $SD_MOUNT_POINT/$FILE_ZIMAGE not exists"
		exit 1
	fi

	# Check device tree
	if [ ! -f "$SD_MOUNT_POINT/$FILE_DEVICETREE" ]; then
		echo "===> Update failed, $SD_MOUNT_POINT/$FILE_DEVICETREE not exists"
		exit 1
	fi

	# Check filesystem
	if [ ! -f "$SD_MOUNT_POINT/$FILE_FILESYSTEM" ]; then
		echo "===> Update failed, $SD_MOUNT_POINT/$FILE_FILESYSTEM not exists"
		exit 1
	fi

	# Check uEnv
	if [ ! -d "$SD_MOUNT_POINT/$FILE_UENV" ]; then
		echo "===> Update failed, $SD_MOUNT_POINT/$FILE_UENV not exists"
		exit 1
	fi
}

qspi_update()
{
	echo "===> Updating u-boot.bin to QSPI flash..."
	flashcp "$SD_MOUNT_POINT/$FILE_UBOOT" /dev/mtd0
	echo "===> Initializing u-boot-env partitions..."
	dd if=/dev/zero of=/dev/mtd2 bs=1024 count=128 > /dev/null 2>&1
	dd if=/dev/zero of=/dev/mtd3 bs=1024 count=128 > /dev/null 2>&1
}

emmc_partition()
{
	#
	# Format the eMMC, the partition table were be deleted
	#
	umount $EMMC_DRIVE"p1" > /dev/null 2>&1
	umount $EMMC_DRIVE"p2" > /dev/null 2>&1
	umount $EMMC_DRIVE"p3" > /dev/null 2>&1

	dd if=/dev/zero of=$EMMC_DRIVE bs=1024 count=1024
	if [ $? -ne 0 ]; then
		echo "===> Format emmc failed"
		exit 1
	fi

	SIZE=`fdisk -l $EMMC_DRIVE | grep Disk | awk '{print $5}'`

	echo DISK SIZE - $SIZE bytes

	CYLINDERS=475 #`echo $SIZE/255/63/512 | bc`

	#
	# Repartition eMMC
	# first partition: rootfs, ext4, 680MB
	# second partition: extended, vfat, 2.9GB
	#
#	sfdisk -D -H 255 -S 63 -C $CYLINDERS $EMMC_DRIVE <<EOF
#,9,0x0c,*
#10,190,0x83,-
#200,,0x0c,-
#EOF
	{
	echo ,495352,0x0C,*
	echo ,3092920,,-
	echo ,,,-
	} | sfdisk -u S $EMMC_DRIVE >/dev/null 2>&1

	if [ $? -ne 0 ]; then
		echo "===> eMMC partition failed"
		exit 1
	fi

	umount $EMMC_DRIVE"p1" > /dev/null 2>&1
	sleep 1
	mkfs.fat -F 32 -n "boot" "$EMMC_DRIVE"p1
	if [ $? -ne 0 ]; then
		echo "===> Creating boot partition failed"
		exit 1
	fi

	umount $EMMC_DRIVE"p3" > /dev/null 2>&1
	sleep 1
	mkfs.fat -F 32 -n "extented" "$EMMC_DRIVE"p3
	if [ $? -ne 0 ]; then
		echo "===> Create extended partition failed"
		exit 1
	fi
	
	umount $EMMC_DRIVE"p2" >> /dev/null
	sleep 1
	mkfs.ext4 -L "rootfs" "$EMMC_DRIVE"p2
	if [ $? -ne 0 ]; then
		echo "===> Creating rootfs partition failed"
		exit 1
	fi

	mkdir $EMMC_BOOT_MP
	mount $EMMC_DRIVE"p1" $EMMC_BOOT_MP
	mkdir $EMMC_ROOTFS_MP
	mount -t ext4 $EMMC_DRIVE"p2" $EMMC_ROOTFS_MP
}

emmc_update()
{
	if [ "$1" != "loader2qspi" ]; then
		echo "===> Update loader to emmc..."
		cp $SD_MOUNT_POINT/$FILE_MLO $EMMC_BOOT_MP
		cp $SD_MOUNT_POINT/$FILE_UBOOT $EMMC_BOOT_MP
	fi
	
	echo "===> Updating kernel and devicetree to emmc..."
	cp $SD_MOUNT_POINT/$FILE_ZIMAGE $EMMC_BOOT_MP
	cp $SD_MOUNT_POINT/*.dtb $EMMC_BOOT_MP
	if [ -f $SD_MOUNT_POINT/$FILE_RAMDISK ]; then
		cp $SD_MOUNT_POINT/$FILE_RAMDISK $EMMC_BOOT_MP
	fi

	echo "===> Update uEnv to emmc..."
	cp $SD_MOUNT_POINT/$FILE_UENV -a $EMMC_BOOT_MP
	cp $SD_MOUNT_POINT/$FILE_DEFAULT_UENV $EMMC_BOOT_MP/uEnv.txt

	echo "===> Updating filesystem to emmc..."
	tar mxzf $SD_MOUNT_POINT/$FILE_FILESYSTEM -C $EMMC_ROOTFS_MP
	if [ $? -ne 0 ]; then
		echo "===> Update eMMC failed"
		umount $EMMC_ROOTFS_MP > /dev/null 2>&1
		exit 1
	fi
	sync
}

if [ "$1" = "loader2qspi" ]; then
	echo "All data on eMMC and QSPI flash now will be destroyed! Continue? [y/n]"
else
	echo "All data on eMMC now will be destroyed! Continue? [y/n]"
fi

read ans
if ! [ $ans == 'y' ]
then
    exit
fi

if [ "$1" = "loader2qspi" ]; then
	check_for_qspiflash
fi
check_for_sdcards
check_files_in_sdcard
check_for_emmc
emmc_partition
if [ "$1" = "loader2qspi" ]; then
	qspi_update
	emmc_update $1
else
	emmc_update
fi

echo
echo
if [ "$1" = "loader2qspi" ]; then
	echo -e '\033[0;33;1m Update system completed, The board can be booted from QSPI flash now \033[0m'
else
	echo -e '\033[0;33;1m Update system completed, The board can be booted from eMMC now \033[0m'
fi
echo

exit 0
