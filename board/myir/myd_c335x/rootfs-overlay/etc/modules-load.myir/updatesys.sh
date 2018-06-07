#
# This script to update Linux 4.1.18 system
# This script will respectively update the u-boot, device tree, zImage 
# and the filesystem from sd card to NAND or to eMMC.
#
# Author: MYiR
# Email: support@myirtech.com
# Date: 2015.1.21
#	Initial Version
# Date: 2017.05.24
#	update to kernel4.1.18 and u-boot201605
# Date: 2017.08.22
#	update images from usbmsc or sd
# Date: 2017.09.08
#	update images from sd to NAND
#	update images from sd to emmc 

#!/bin/sh

# The path sdcard mounted
SD_MOUNT_POINT="/media/mmcblk1p1"
# The rootfs partition would be mounted on current 'rootfs' directory

EMMC_BOOT_MP="boot"
EMMC_ROOTFS_MP="rootfs"

if [ "$1" == "loader2usbmsc" ]; then
	FILE_MLO="MLO_usbmsc"
elif [ "$1" == "loader2emmc" ]; then
	FILE_MLO="MLO_emmc"
elif [ "$1" == "loader2nand" ]; then
	FILE_MLO="MLO_nand"
fi
if [ "$1" == "loader2usbmsc" ]; then
	FILE_UBOOT="u-boot_usbmsc.img"
elif [ "$1" == "loader2emmc" ]; then
	FILE_UBOOT="u-boot_emmc.img"
elif [ "$1" == "loader2nand" ]; then
	FILE_UBOOT="u-boot_nand.img"
fi

FILE_ZIMAGE="zImage"
FILE_DEVICETREE="myd_c335x.dtb"
FILE_DEVICETREE_EMMC="myd_c335x_emmc.dtb"
FILE_FILESYSTEM="rootfs.tar.gz"
FILE_FILESYSTEM_NAND="rootfs.ubi"
FILE_RAMDISK="ramdisk.gz"
FILE_UBOOTENV="u-boot-env.bin"
FILE_DEFAULT_UENV="uEnv.txt"

# eMMC  is connected to mmc host 1,  sd is connected to mmc host 0
EMMC_DRIVE=
# usb dom is connected to usb host 1
USBMSC_DRIVE="/dev/sda"

update_success()
{
	if [ "$1" == "loader2usbmsc" ]; then
		echo "timer" > /sys/class/leds/myc:green:user1/trigger
		echo "500" > /sys/class/leds/myc:green:user1/delay_off
		echo "500" > /sys/class/leds/myc:green:user1/delay_on
	elif [ "$1" == "loader2emmc" ]; then
		echo "timer" > /sys/class/leds/myc:green:user1/trigger
		echo "500" > /sys/class/leds/myc:green:user1/delay_off
		echo "500" > /sys/class/leds/myc:green:user1/delay_on
	elif [ "$1" == "loader2nand" ]; then
		echo "timer" > /sys/class/leds/myc:green:user1/trigger
		echo "500" > /sys/class/leds/myc:green:user1/delay_off
		echo "500" > /sys/class/leds/myc:green:user1/delay_on
	fi
}

update_fail()
{
	if [ "$1" == "loader2usbmsc" ]; then
		echo "timer" > /sys/class/leds/myc:green:user1/trigger
		echo "100" > /sys/class/leds/myc:green:user1/delay_off
		echo "100" > /sys/class/leds/myc:green:user1/delay_on
	elif [ "$1" == "loader2emmc" ]; then
		echo "timer" > /sys/class/leds/myc:green:user1/trigger
		echo "100" > /sys/class/leds/myc:green:user1/delay_off
		echo "100" > /sys/class/leds/myc:green:user1/delay_on
	elif [ "$1" == "loader2nand" ]; then
		echo "timer" > /sys/class/leds/myc:green:user1/trigger
		echo "100" > /sys/class/leds/myc:green:user1/delay_off
		echo "100" > /sys/class/leds/myc:green:user1/delay_on
	fi
}

check_for_emmc()
{
	#
	# Check the eMMC was whether identified or not
	#
	mmc_card=$(basename $(dirname $(grep -l 'MMC$' /sys/bus/mmc/devices/*/type)))

	if [ -d  /sys/bus/mmc/devices/$mmc_card/block/mmcblk0/ ]; then
		EMMC_DRIVE="/dev/mmcblk0"
	elif [ -d  /sys/bus/mmc/devices/$mmc_card/block/mmcblk1/ ]; then
		EMMC_DRIVE="/dev/mmcblk1"
	else
		echo -e "===> No valid emmc"
		exit 1
	fi
	
	echo  "===> found emmc "$EMMC_DRIVE " on " $mmc_card
}

check_for_usbmsc()
{
	if [ -e "$USBMSC_DRIVE" ]; then
		echo  "===> found usbmsc  on "$USBMSC_DRIVE""
	else
		update_fail $1 $2
		exit 1
	fi
	
	if [ ! -d "$SD_MOUNT_POINT" ]; then
		busybox mkdir -p $SD_MOUNT_POINT
	fi
}

check_for_sdcards()
{
	while true; do
	SD_DRIVE=""

	sd_card=$(basename $(dirname $(grep -l 'SD$' /sys/bus/mmc/devices/*/type)))  > /dev/null 2>&1

	# Find the avaible SD cards
	if [ -d  /sys/bus/mmc/devices/$sd_card/block/mmcblk0/ ]; then
		SD_DRIVE="/dev/mmcblk0"
		break
	elif [ -d  /sys/bus/mmc/devices/$sd_card/block/mmcblk1/ ]; then
		SD_DRIVE="/dev/mmcblk1"
		break
	else
		echo -e "===> Please insert a SD/TF card with update images to continue\n"
		while true; do
			busybox  sleep 1
			read -p "Type 'y' to re-detect the SD card or 'n' to exit the script: " REPLY
			if [ "$REPLY" = 'n' ]; then
				update_fail $1 $2
				exit 1
			fi
			break
		done
	fi
	done
	echo  "===> found sdcard "$SD_DRIVE " on " $sd_card
	
	if [ ! -d "$SD_MOUNT_POINT" ]; then
		busybox mkdir -p $SD_MOUNT_POINT
	fi

	busybox umount $SD_MOUNT_POINT  > /dev/null 2>&1
        busybox mount -t vfat $SD_DRIVE"p1" $SD_MOUNT_POINT > /dev/null 2>&1

}

check_files_in_sdcard()
{
	# Check MLO
	if [ ! -f "$SD_MOUNT_POINT/$FILE_MLO" ]; then
		echo "===> Update failed, $SD_MOUNT_POINT/$FILE_MLO not exists"
		update_fail $1 $2
		exit 1
	fi

	# Check  u-boot.img for emmc or usb dom
	if [ ! -f "$SD_MOUNT_POINT/$FILE_UBOOT" ]; then
		echo "===> Update failed, $SD_MOUNT_POINT/$FILE_UBOOT not exist"
		update_fail $1 $2
		exit 1
	fi

	# Check zImage
	if [ ! -f "$SD_MOUNT_POINT/$FILE_ZIMAGE" ]; then
		echo "===> Update failed, $SD_MOUNT_POINT/$FILE_ZIMAGE not exists"
		update_fail $1 $2
		exit 1
	fi

	# Check device tree
	if [ -z $(ls $SD_MOUNT_POINT/$FILE_DEVICETREE 2>/dev/null) ]; then
		echo "===> Update failed, $SD_MOUNT_POINT/$FILE_DEVICETREE not exists"
		update_fail $1 $2
		exit 1
	fi

	# Check filesystem
	if [ "$1" == "loader2emmc" ]; then
		if [ ! -f "$SD_MOUNT_POINT/$FILE_FILESYSTEM" ]; then
			echo "===> Update failed, $SD_MOUNT_POINT/$FILE_FILESYSTEM not exists"
			update_fail $1 $2
			exit 1
		fi
	fi
	if [ "$1" == "loader2nand" ]; then
		if [ ! -f "$SD_MOUNT_POINT/$FILE_FILESYSTEM_NAND" ]; then
			echo "===> Update failed, $SD_MOUNT_POINT/$FILE_FILESYSTEM_NAND not exists"
			update_fail $1 $2
			exit 1
		fi
	fi

	# Check uEnv
	if [ "$1" == "loader2emmc" ]; then
		FILE_DEFAULT_UENV="uEnv_mmc.txt";
	elif [ "$1" == "loader2usbmsc" ]; then
		FILE_DEFAULT_UENV="uEnv_usbmsc.txt";
	fi
	if [ ! -e "$SD_MOUNT_POINT/$FILE_DEFAULT_ENV" ]; then
		echo "===> Update failed, $SD_MOUNT_POINT/$FILE_DEFAULT_UENV not exists"
		update_fail $1 $2
		exit 1
	fi
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
		update_fail $1 $2
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
	echo ,2092920,0x0C,*
	echo ,2092920,,-
	echo ,,,-
	} | sfdisk -u S $EMMC_DRIVE >/dev/null 2>&1

	if [ $? -ne 0 ]; then
		echo "===> eMMC partition failed"
		update_fail $1 $2
		exit 1
	fi

	umount $EMMC_DRIVE"p1" > /dev/null 2>&1
	sleep 1
	mkfs.fat -F 32 -n "boot" "$EMMC_DRIVE"p1  > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "===> Creating boot partition failed"
		update_fail $1 $2
		exit 1
	fi

	umount $EMMC_DRIVE"p3" > /dev/null 2>&1
	sleep 1
	mkfs.fat -F 32 -n "extented" "$EMMC_DRIVE"p3  > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "===> Create extended partition failed"
		update_fail $1 $2
		exit 1
	fi
	
	umount $EMMC_DRIVE"p2" > /dev/null 2>&1
	sleep 1
	mkfs.ext4 -L "rootfs" "$EMMC_DRIVE"p2  > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "===> Creating rootfs partition failed"
		update_fail $1 $2
		exit 1
	fi

	mkdir -p $EMMC_BOOT_MP  > /dev/null 2>&1
	mount $EMMC_DRIVE"p1" $EMMC_BOOT_MP  > /dev/null 2>&1
	mkdir -p $EMMC_ROOTFS_MP  > /dev/null 2>&1
	mount -t ext4 $EMMC_DRIVE"p2" $EMMC_ROOTFS_MP  > /dev/null 2>&1
}

usbmsc_partition()
{
	#
	# Format the usb dom, the partition table were be deleted
	#
	umount $USBMSC_DRIVE"1" > /dev/null 2>&1
	umount $USBMSC_DRIVE"2" > /dev/null 2>&1
	umount $USBMSC_DRIVE"3" > /dev/null 2>&1

	dd if=/dev/zero of=$USBMSC_DRIVE bs=1024 count=1024
	if [ $? -ne 0 ]; then
		echo "===> Format usb dom failed"
		update_fail $1 $2
		exit 1
	fi

	SIZE=`fdisk -l $USBMSC_DRIVE | grep Disk | awk '{print $5}'`

	echo DISK SIZE - $SIZE bytes

	CYLINDERS=475 #`echo $SIZE/255/63/512 | bc`

	#
	# Repartition usb dom  
	# first partition: rootfs, ext4, 680MB
	# second partition: extended, vfat, 2.9GB
	#
#	sfdisk -D -H 255 -S 63 -C $CYLINDERS $USBMSC_DRIVE <<EOF
#,9,0x0c,*
#10,190,0x83,-
#200,,0x0c,-
#EOF
	{
	echo ,395352,0x0C,*
	echo ,2092920,,-
	echo ,,,-
	} | sfdisk -u S $USBMSC_DRIVE >/dev/null 2>&1

	if [ $? -ne 0 ]; then
		echo "===> usb dom partition failed"
		update_fail $1 $2
		exit 1
	fi

	umount $USBMSC_DRIVE"1" > /dev/null 2>&1
	sleep 1
	mkfs.fat -F 32 -n "boot" "$USBMSC_DRIVE"1  > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "===> Creating boot partition failed"
		update_fail $1 $2
		exit 1
	fi

	umount $USBMSC_DRIVE"3" > /dev/null 2>&1
	sleep 1
	mkfs.fat -F 32 -n "extented" "$USBMSC_DRIVE"3  > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "===> Create extended partition failed"
		update_fail $1 $2
		exit 1
	fi
	
	umount $USBMSC_DRIVE"2" > /dev/null 2>&1
	sleep 1
	mkfs.ext4 -L "rootfs" "$USBMSC_DRIVE"2  > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "===> Creating rootfs partition failed"
		update_fail $1 $2
		exit 1
	fi

	mkdir -p $EMMC_BOOT_MP  > /dev/null 2>&1
	mount $USBMSC_DRIVE"1" $EMMC_BOOT_MP  > /dev/null 2>&1
	mkdir -p $EMMC_ROOTFS_MP  > /dev/null 2>&1
	mount -t ext4 $USBMSC_DRIVE"2" $EMMC_ROOTFS_MP  > /dev/null 2>&1
}

emmc_update()
{
	echo "===> Update loader to emmc..."
	cp $SD_MOUNT_POINT/$FILE_MLO "$EMMC_BOOT_MP"/MLO
	cp $SD_MOUNT_POINT/MLO_* "$EMMC_BOOT_MP"/
	cp $SD_MOUNT_POINT/$FILE_UBOOT "$EMMC_BOOT_MP"/u-boot.img
	cp $SD_MOUNT_POINT/u-boot_*.img "$EMMC_BOOT_MP"/
	
	echo "===> Updating kernel and devicetree to emmc..."
	cp $SD_MOUNT_POINT/$FILE_ZIMAGE $EMMC_BOOT_MP
	cp $SD_MOUNT_POINT/$FILE_DEVICETREE_EMMC $EMMC_BOOT_MP
	cp $SD_MOUNT_POINT/$FILE_DEVICETREE $EMMC_BOOT_MP
	if [ -f $SD_MOUNT_POINT/$FILE_RAMDISK ]; then
		cp $SD_MOUNT_POINT/$FILE_RAMDISK $EMMC_BOOT_MP
	fi

	echo "===> Update uEnv to emmc..."
	cp $SD_MOUNT_POINT/$FILE_DEFAULT_UENV $EMMC_BOOT_MP/uEnv.txt
	cp $SD_MOUNT_POINT/uEnv_*.txt $EMMC_BOOT_MP/

	echo "===> Updating filesystem to emmc..."
	cp $SD_MOUNT_POINT/$FILE_FILESYSTEM $EMMC_BOOT_MP/
	tar xzmf $SD_MOUNT_POINT/$FILE_FILESYSTEM -C $EMMC_ROOTFS_MP
	if [ $? -ne 0 ]; then
		echo "===> Update eMMC failed"
		umount $EMMC_ROOTFS_MP > /dev/null 2>&1
		update_fail $1 $2
		exit 1
	fi
	sync
}

usbmsc_update()
{
	echo "===> Update loader to usb dom..."
	cp $SD_MOUNT_POINT/$FILE_MLO "$EMMC_BOOT_MP"/MLO
	cp $SD_MOUNT_POINT/MLO_* "$EMMC_BOOT_MP"/
	cp $SD_MOUNT_POINT/$FILE_UBOOT "$EMMC_BOOT_MP"/u-boot.img
	cp $SD_MOUNT_POINT/u-boot_*.img "$EMMC_BOOT_MP"/
	
	echo "===> Updating kernel and devicetree to usb dom..."
	cp $SD_MOUNT_POINT/$FILE_ZIMAGE $EMMC_BOOT_MP
	cp $SD_MOUNT_POINT/$FILE_DEVICETREE $EMMC_BOOT_MP
	cp $SD_MOUNT_POINT/$FILE_DEVICETREE_EMMC $EMMC_BOOT_MP
	if [ -f $SD_MOUNT_POINT/$FILE_RAMDISK ]; then
		cp $SD_MOUNT_POINT/$FILE_RAMDISK $EMMC_BOOT_MP
	fi

	echo "===> Update uEnv to usb dom ..."
	cp $SD_MOUNT_POINT/$FILE_DEFAULT_UENV $EMMC_BOOT_MP/uEnv.txt
	cp $SD_MOUNT_POINT/uEnv_*.txt $EMMC_BOOT_MP/

	echo "===> Updating filesystem to usb dom ..."
	cp $SD_MOUNT_POINT/$FILE_FILESYSTEM $EMMC_BOOT_MP/
	tar xzmf $SD_MOUNT_POINT/$FILE_FILESYSTEM -C $EMMC_ROOTFS_MP
	if [ $? -ne 0 ]; then
		echo "===> Update usb dom failed"
		umount $EMMC_ROOTFS_MP > /dev/null 2>&1
		update_fail $1 $2
		exit 1
	fi
	sync
}

check_for_nand()
{
        # Find the avaible nand falsh
        PARTITION_TEST=`cat /proc/mtd | grep 'NAND.'`
        if [ "$PARTITION_TEST" = "" ]; then
                echo -e "===> Not NAND flash was found"
                if [ "$1" = "nand" ]; then
                        update_fail
                        exit 1
                fi
        fi
}

nand_update()
{
        echo "===> Updating images to NAND flash..."
        flash_erase /dev/mtd0 0 0
        nandwrite -p /dev/mtd0 $SD_MOUNT_POINT/$FILE_MLO
        flash_erase /dev/mtd1 0 0
        nandwrite -p /dev/mtd1 $SD_MOUNT_POINT/$FILE_MLO
        flash_erase /dev/mtd2 0 0
        nandwrite -p /dev/mtd2 $SD_MOUNT_POINT/$FILE_MLO
        flash_erase /dev/mtd3 0 0
        nandwrite -p /dev/mtd3 $SD_MOUNT_POINT/$FILE_MLO
        flash_erase /dev/mtd4 0 0
        nandwrite -p /dev/mtd4 $SD_MOUNT_POINT/$FILE_DEVICETREE
        flash_erase /dev/mtd5 0 0
        nandwrite -p /dev/mtd5 $SD_MOUNT_POINT/$FILE_UBOOT
        flash_erase /dev/mtd6 0 0
        flash_erase /dev/mtd7 0 0
        flash_erase /dev/mtd8 0 0
        nandwrite -p /dev/mtd8 $SD_MOUNT_POINT/$FILE_ZIMAGE
        flash_erase /dev/mtd9 0 0
        ubiformat /dev/mtd9 -f $SD_MOUNT_POINT/$FILE_FILESYSTEM_NAND  -s 2048 -O 2048
        sync


}

if [ "$1" = "loader2usbmsc" ]; then
	echo "All data on usb dom now will be destroyed! Continue? [y/n]"
elif [ "$1" == "loader2emmc" ]; then
	echo "All data on eMMC now will be destroyed! Continue? [y/n]"
elif [ "$1" == "loader2nand" ]; then
	echo "All data on NAND Flash now will be destroyed! Continue? [y/n]"
fi

read ans
if ! [ $ans == 'y' ]
then
    exit
fi

if [ "$2" == "usbmsc" ]; then
check_for_usbmsc
busybox umount $SD_MOUNT_POINT  > /dev/null 2>&1
busybox mount -t vfat $USBMSC_DRIVE"1" $SD_MOUNT_POINT > /dev/null 2>&1
fi
if [ "$2" == "sd" ]; then
check_for_sdcards
fi
check_files_in_sdcard $1 $2

if [ "$1" == "loader2emmc" ]; then
check_for_emmc
emmc_partition
emmc_update $1 $2
fi
if [ "$1" == "loader2usbmsc" ]; then
check_for_usbmsc
usbmsc_partition
usbmsc_update $1 $2
fi

if [ "$1" == "loader2nand" ]; then
check_for_nand
nand_update $1 $2
fi
echo
echo
if [ "$1" = "loader2usbmsc" ]; then
	echo -e '\033[0;33;1m Update system completed, The board can be booted from usb dom now \033[0m'
elif [ "$1" == "loader2emmc" ]; then
	echo -e '\033[0;33;1m Update system completed, The board can be booted from eMMC now \033[0m'
elif [ "$1" == "loader2nand" ]; then
	echo -e '\033[0;33;1m Update system completed, The board can be booted from NAND Flash now \033[0m'
fi
	update_success $1 $2
echo

exit 0
