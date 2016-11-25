#!/bin/sh

echo -e "\033[31mRunning Upgrade Script...\033[0m"

#Driver Mode 1 WiFi mode, 2 for Eval/PER Mode, 3 for Firmware_upgrade
rm firmware/flash_content
#cp RS9113_RS8111_calib_values.txt RS9113_RS8111_calib_values_copy.txt
sed -e 's/,//g' RS9113_RS8111_calib_values.txt > RS9113_RS8111_calib_values_copy.txt
xxd -r -ps RS9113_RS8111_calib_values_copy.txt firmware/flash_content
rm RS9113_RS8111_calib_values_copy.txt 
cp RS9113_RS8111_calib_values.txt /home/rsi/release/ -rf
cp firmware/flash_content  /home/rsi/release/firmware/ -rf
sh /home/rsi/release/remove.sh
sleep 2;
echo -e "\033[31mRmmoding any left *.ko....\033[0m"
touch /home/rsi/release/flash.sh
#sed 's/=2/=5/' /home/rsi/release/insert.sh > /home/rsi/release/insert_up.sh 
echo -e "\033[31mEntered into Upgrade Mode....\033[0m"
echo -e "\033[31mInserting .kos with Driver Mode 3....\033[0m"
sh /home/rsi/release/flash.sh

sleep 2
state=`cat /proc/OBM-wlan/stats | grep "DRIVER_FSM_STATE" | cut -d ' ' -f 2 | cut -d '(' -f 1`
#state=FSM_MAC_INIT_DONE

if [ "$state" ==  "FSM_MAC_INIT_DONE" ]
then 
	sh /home/rsi/release/remove.sh
 echo -e "\033[31mUpgrade Successful...\033[0m"
#	sleep 5;
#	sh /home/rsi/release/insert.sh
# state=`cat /proc/onebox-mobile/stats | grep "DRIVER_FSM_STATE" | cut -d ' ' -f 2 | cut -d '(' -f 1`
# if [ "$state" ==  "FSM_MAC_INIT_DONE" ]
# then 
# echo -e "\033[31mEntered into Normal Mode....\033[0m"
# else
# echo -e "\033[31mUnable to find proc entry...\033[0m"
# fi
else
	echo -e "\033[31m !!!!! DANGER !!!!\033[0m"
	echo -e "\033[31m Upgrade Failed\033[0m"
	echo -e "\033[31m Upgrade Failed\033[0m"
fi

