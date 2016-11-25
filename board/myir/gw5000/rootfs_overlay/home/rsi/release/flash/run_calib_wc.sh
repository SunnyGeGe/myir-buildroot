cd ../release/flash/
rm flash non_rf_values* pmem* -rf
gcc -o flash rsi_calib_flash.c rsi_api_routine.c
./flash 2

#status=`./flash | grep -i -m 1 "WARNING" | cut -d ' ' -f 1`
#if [ "$status" ==  "WARNING" ]
#then 
#	echo -e "\033[31m !!!!! DANGER !!!!\033[0m"
#	echo -e "\033[31m UNABLE TO CREATE FLASH FILe\033[0m"
#	echo -e "\033[31m Upgrade Failed\033[0m"
#  exit 0
#else
# echo -e "\033[31mCreating flash file...\033[0m"
#fi

#objcopy -O binary -j .eeprom_value_section flash p1
#cat p1 > non_rf_values
#cat p1 | od -v -w1 -tx1 | awk '{print $2;}' |  sed -e '/^$/d' > non_rf_values.txt
#sed -e 's/$/,/g' non_rf_values.txt > non_rf_values1.txt
#sed -e 's/^/0x/g' non_rf_values1.txt > non_rf_values.txt
cat RS9113_RS8111_calib_values.txt >> non_rf_values.txt
sed -e '/0x.,/s/0x/0x0/g' non_rf_values.txt > non_rf_values2.txt 
cp non_rf_values2.txt RS9113_RS8111_calib_values.txt
cat WC/dump_zero.txt >> RS9113_RS8111_calib_values.txt 
#sed -e '4097,$g/0x00/d' RS9113_RS8111_calib_values.txt > non_rf_values.txt
sed -e '4097,$d' RS9113_RS8111_calib_values.txt > non_rf_values3.txt
cat WC/RS9113_WC_BL_0_5_hex_8 >> non_rf_values3.txt 
cp non_rf_values3.txt RS9113_RS8111_calib_values.txt
rm p1 non_rf_values* -rf
#cp RS9113_RS8111_calib_values.txt host_flash_new_rf_upgrade/release/
cp RS9113_RS8111_calib_values.txt ../ -rf
cd ../
sh upgrade.sh
sh insert.sh 
sleep 1
echo -e " \n\033[31m Verifying FLASH ....\033[0m"
./onebox_util rpine0 verify_flash
status=`./onebox_util rpine0 verify_flash | grep -i -m 1 "Failed" | cut -d ' ' -f 2`
if [ "$status" ==  "Failed" ]
then 
	echo -e "\033[31m !!!!! DANGER !!!!\033[0m"
	echo -e "\033[31m Upgrade Failed\033[0m"
	echo -e "\033[31m Upgrade Failed\033[0m"
  exit 1
else
 echo -e "\033[31mUpgrade Successful...\033[0m"
 cd  flash/
 ./flash 3
 cd ../
fi

 
echo -e " \n\033[31m WLAN MAC_ID ....\033[0m"
./onebox_util rpine0 eeprom_read 6 45
echo -e " \n\033[31m BT MAC_ID ....\033[0m"
./onebox_util rpine0 eeprom_read 6 56
echo -e " \n\033[31m Zigbee MAC_ID ....\033[0m"
./onebox_util rpine0 eeprom_read 8 67
echo -e " \n\033[31m MBR ....\033[0m"
./onebox_util rpine0 eeprom_read 16 0
echo -e " \n\033[31m FLASH SIZE ....\033[0m"
./onebox_util rpine0 eeprom_read 4 22
echo -e " \n\033[31m BB/RF CALIB MAGIC WORD....\033[0m"
./onebox_util rpine0 eeprom_read 6 424
echo -e " \n\033[31m Bootloader Code ....\033[0m"
./onebox_util rpine0 eeprom_read 6 4096

echo -e " \n\033[31m BB TX_BCOS value ....\033[0m "
./onebox_util rpine0 bb_read 319
echo -e " \n\033[31m BB TX_BSIN value ....\033[0m"
./onebox_util rpine0 bb_read 31a
echo -e " \n\033[31m BB DPD 0x0F03 value ....\033[0m"
./onebox_util rpine0 bb_read f03
echo -e " \n\033[31m BB DPD 0x0F04 value ....\033[0m"
./onebox_util rpine0 bb_read f04
echo -e " \n\033[31m BB DPD 0x0F05 value ....\033[0m"
./onebox_util rpine0 bb_read f05
echo -e " \n\033[31m BB DPD 0x0F06 value ....\033[0m"
./onebox_util rpine0 bb_read f06
echo -e " \n\033[31m BB DPD 0x0F10 value ....\033[0m"
./onebox_util rpine0 bb_read f10
echo -e " \n\033[31m BB DPD 0x0F02 value ....\033[0m"
./onebox_util rpine0 bb_read f02

sh /home/rsi/release/remove.sh
cd -
#rm RS9113_RS8111_calib_values.txt ../ -rf
