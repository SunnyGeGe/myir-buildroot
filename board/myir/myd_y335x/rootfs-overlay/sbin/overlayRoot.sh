#!/bin/sh
fail()
{
    echo -e "$1"    
    /bin/bash
}
#exec /sbin/init
echo "[OVERLAY] Overlay starting..."
mount -t proc proc /proc
mount -t sysfs sysfs /sys

if [ ! -d /sys/class/ubi/ubi1 ]; then
	echo "[OVERLAY] Overlay attaching failed."
	flash_eraseall /dev/mtd15
	ubiformat -y -q -e 0 /dev/mtd15 -s 2048 -O 2048
	ubiattach /dev/ubi_ctrl -m 15 -O 2048
	ubimkvol /dev/ubi1 -N overlay -m
	mount -t ubifs ubi1_0 /overlay
else
	echo "[OVERLAY] Overlay attached successfully."
	if [ ! -d /sys/class/ubi/ubi1_0 ]; then
		ubimkvol /dev/ubi1 -N overlay -m
	fi
	mount -t ubifs ubi1_0 /overlay
	if [ ! -f /overlay/upper/usr/boot ]; then
		echo "[OVERLAY] Last boot failed or first boot! trying recover to factory."
		umount /overlay
		ubidetach -m 15
		flash_eraseall /dev/mtd15
		ubiformat -y -q -e 0 /dev/mtd15 -s 2048 -O 2048
		ubiattach /dev/ubi_ctrl -m 15 -O 2048
		ubimkvol /dev/ubi1 -N overlay -m
		mount -t ubifs ubi1_0 /overlay
	else
		BOOTTIME=`cat overlay/upper/usr/boot`
		echo "[OVERLAY] Last login:  $BOOTTIME"
		rm -rf /overlay/upper/usr/boot
	fi
fi

#mount -t jffs2 /dev/mtdblock15 /overlay


mkdir -p /overlay/upper
mkdir -p /overlay/work
mount -o remount,ro /
mount -t overlay overlay -o rw,noatime,lowerdir=/,upperdir=/overlay/upper,workdir=/overlay/work  /system

#mount -n -o noatime --move /proc  /system/proc
mount -n -o noatime --move /dev  /system/dev
#mount -n -o noatime --move /tmp  /system/tmp
#mount -n -o noatime --move /run  /system/run
mount -n -o noatime --move /sys  /system/sys

pivot_root  /system  /system/rom
mount -n -o noatime --move /rom/overlay  /overlay

exec /sbin/init
