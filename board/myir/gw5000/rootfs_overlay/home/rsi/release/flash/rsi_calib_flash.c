#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "rsi_api_routine.h"

extern test_params_t test_params;
unsigned int mbr_dump[] = {
#include "WC/mbr_hex_dump"
};  

#define MBR_DUMP_SIZE 16

char module[] = "RS9113-0301-WBZ0";

#define WLAN_MAC_ID_LS_BYTE   0x38
#define ZIGBEE_MAC_ID_LS_BYTE 0x09

struct eeprom_values
{
	unsigned int bootloader[4];
	unsigned int  sw_feature_enable;
	unsigned char flash_vendor_type;
	unsigned char flash_variant;
	unsigned int  flash_size;
	unsigned char padding[14];
	unsigned char wlan_magic_word;
	unsigned int  wlan_enables;
	unsigned char wlan_mac_id[6];
	unsigned char bt_magic_word;
	unsigned int bt_enables;
	unsigned char bt_mac_id[6];
	unsigned char zigbee_magic_word;
	unsigned int zb_enables;
	unsigned char zigbee_mac_id[8];
	unsigned char common_magic_word[2];
	unsigned char	eeprom_version[2];
	unsigned char	module_num[16];
	unsigned char reserved[329];
}__attribute__ ((packed))values  __attribute__ ((section(".eeprom_value_section"))) =
{
	.bootloader = {0x00000000},
	.sw_feature_enable = 0,
	.flash_vendor_type = 0,
	.flash_variant = 0,
	.flash_size = 0,
	.wlan_magic_word = 0x5A,
	.wlan_enables   = 0,
	.wlan_mac_id = {0x00, 0x23, 0xA7, 0x1B, 0x15, 0x00},
	.bt_magic_word = 0x5A,
	.bt_enables = 0,
	.bt_mac_id = {0x00, 0x23, 0xA7, 0x1B, 0x15, 0x00},
	.zigbee_magic_word = 0x5A,
	.zb_enables = 0,
	.zigbee_mac_id = {0x00, 0x23, 0xA7, 0x00, 0x00, 0x00, 0x00, 0x00},
	.common_magic_word = {0x5A, 0},
	.eeprom_version = {2, 0},
	.module_num = {"RS9113-0003-WBZ0"},
	.reserved = {}
};


void append(FILE *head, FILE *tail)
{
    char buf[1024];
    size_t n;
    while ((n = fread(buf, 1, sizeof buf, tail)) > 0)
        if (fwrite(buf, 1, n, head) != n)
            abort();
    if (ferror(tail))
        abort();
}

void rsi_copy_mac_info(char *mac, int test_mac, int bytes)
{
  unsigned char *temp;

  temp = (unsigned char *)&test_mac;
  bytes--;
  do 
  {
    *mac = temp[bytes];
    mac++;
  } while (bytes--);
}  

int main (int argc, char *argv[])
{
	int i = 0;
	FILE *pFile;
	unsigned char *temp;
  unsigned char query;
  int status = RSI_STATUS_SUCCESS;
  int type;

  if (argc > 1)
  {  
    type = atoi(argv[1]);
  }
  else
  {
      printf("\nWARNING SENDING LESS NUMBER OF ARGUMENTS\n");
      return RSI_STATUS_FAILURE;
  }  
  if (type == 1 || type == 2)
  {  
    pFile = fopen("non_rf_values.txt", "w");
    //	pFile = fopen(argv[1], "w");
    if(pFile == NULL)
    {
      printf("Unable to create a file\n");
      return RSI_STATUS_FAILURE;
    }
    if (rsi_read_config() != RSI_STATUS_SUCCESS)
    {
      printf("\nWARNING READING CONFIG FILE FAILURE\n");
      return RSI_STATUS_FAILURE;
    }


    if((test_params.wlan_mac_id < test_params.start_mac_id) || 
        ((test_params.wlan_mac_id + test_params.num_wlan_macs) > test_params.end_mac_id) || 
        (test_params.wlan_mac_id & 0x03))
    {
      printf("\nWARNING WLAN MAC ADDRESS FOUND OUT OF RANGE\n");
      return RSI_STATUS_FAILURE;
    }
    if((test_params.zigbee_mac_id < test_params.zigbee_start_mac_id) || (test_params.zigbee_mac_id > test_params.zigbee_end_mac_id))
    {
      printf("\nWARNING ZIGBEE MAC ADDRESS FOUND OUT OF RANGE\n");
      return RSI_STATUS_FAILURE;
    }
    if((test_params.bt_mac_id < test_params.bt_start_mac_id) || (test_params.bt_mac_id > test_params.bt_end_mac_id))
    {
      printf("\nWARNING BT MAC ADDRESS FOUND OUT OF RANGE\n");
      return RSI_STATUS_FAILURE;
    }


#ifdef RSI_LOG
    printf("wlan_mac 0x%x \n",test_params.wlan_mac_id);
    printf("zigbee_mac 0x%x \n",test_params.zigbee_mac_id);
    printf("bt_mac 0x%x \n",test_params.bt_mac_id);
#endif  
    rsi_copy_mac_info(&values.wlan_mac_id[3], test_params.wlan_mac_id, 3);
    rsi_copy_mac_info(&values.bt_mac_id[3], test_params.bt_mac_id, 3);
    rsi_copy_mac_info(&values.zigbee_mac_id[5], test_params.zigbee_mac_id, 3);
    values.flash_size = test_params.flash_size;
    
    //! FOR WISE-CONNECT modules  
    if (type == 2)
    {  
      printf("WISE CONNECT MODULE \n");
      memcpy(&values.bootloader[0], mbr_dump, MBR_DUMP_SIZE);
      values.flash_size = 0x800; //2MB flash
      memcpy(&values.module_num[0], module, 16);
    }
#ifdef RSI_LOG
    printf("wlan_mac 0x%x \n", *(unsigned int *)&values.wlan_mac_id[3]);
    printf("BT_mac 0x%x \n", *(unsigned int *)&values.bt_mac_id[3]);
    printf("Zigbee_mac 0x%x \n", *(unsigned int *)&values.zigbee_mac_id[5]);
    printf("flash_size %x\n",values.flash_size);
#endif  
    temp = (unsigned char *)&values.bootloader[0]; 
    for (i = 0; i< sizeof(values); i++)
      fprintf(pFile, "0x%x,\n",temp[i]);
    fclose(pFile);
    test_params.wlan_mac_id += 4;
    test_params.zigbee_mac_id += 1;
    test_params.bt_mac_id += 1;
#if 0
    printf("DO YOU WANT TO FLASH: (y or n ) ");
	scanf("%c",&query);
    if (query == 'y')
    {
      printf("PROCEEDING TO BURN FLASH \n");
    }
    else 
    {
      printf("WARNING SKIPPING FLASH BURNING \n");
      return RSI_STATUS_FAILURE;
    }
#endif  	
    return RSI_STATUS_SUCCESS;
  }
  else if (type == 3) 
  {
    if (rsi_read_config() != RSI_STATUS_SUCCESS)
    {
      printf("\nWARNING READING CONFIG FILE FAILURE\n");
      return RSI_STATUS_FAILURE;
    }
    printf("\nUPDATING LAST MAC FILE \n");
    test_params.wlan_mac_id += 4;
    test_params.zigbee_mac_id += 1;
    test_params.bt_mac_id += 1;
    if (rsi_save_mac() != RSI_STATUS_SUCCESS)
    {
      printf("\nWARNING ERROR IN SAVING LAST MAC FILE \n");
      return RSI_STATUS_FAILURE;
    }
    return RSI_STATUS_SUCCESS;
  }
}	
