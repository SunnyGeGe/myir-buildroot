#!/bin/bash

mmcblk="/dev/mmcblk0"
mmcp=$mmcblk

    while true; do
        while true; do
            if [ -b "$mmcblk" ]; then
              busybox  sleep 1
                if [ -b "$mmcblk" ]; then
                    echo "tf card insert"
                    break
                fi
            else
               busybox sleep 1
            fi
        done
        
        if [ ! -d "/tmp/extsd" ]; then
            busybox mkdir -p /tmp/extsd
        fi
        
        mmcp=$mmcblk
	busybox umount $mmcp  > /dev/null 2>&1
        busybox mount -t vfat $mmcp /tmp/extsd 
        if [ $? -ne 0 ]; then
            mmcp=$mmcblk"p1"
	   busybox umount $mmcp  > /dev/null 2>&1
           busybox mount -t vfat $mmcp /tmp/extsd
            if [ $? -ne 0 ]; then
                exit -1
                busybox sleep 3
                continue 2
            fi
        fi

        break
    done
	
    if [ ! -f /tmp/extsd/sdcard.img ]; then

	echo "sdcard.img not found, updatesys failed!"
	exit -1
    fi
    

    dd bs=1M if=/tmp/extsd/sdcard.img | pv | dd of=/dev/mmcblk1

    busybox umount /tmp/extsd  > /dev/null 2>&1
    

