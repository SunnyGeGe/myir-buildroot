
#include <stdio.h>
#include <string.h>
#include "rsi_api_routine.h"

test_params_t test_params;

/**********************************************************************
 * Update next MAC ADDRESS in the file
 * ********************************************************************/

int rsi_save_mac()
{
  FILE *rsi_last_mac;
  rsi_last_mac = fopen("RSI_LastMac.txt","w");
  if (rsi_last_mac == NULL)
  {
    printf("Unable to create LAST MAC file\n");
    return RSI_STATUS_FAILURE;
  }  
  fprintf(rsi_last_mac,"RSI_LAST_WLAN_MAC_ID=%x\n",test_params.wlan_mac_id);
  fprintf(rsi_last_mac,"RSI_LAST_ZIGBEE_MAC_ID=%x\n",test_params.zigbee_mac_id);
  fprintf(rsi_last_mac,"RSI_LAST_BT_MAC_ID=%x\n",test_params.bt_mac_id);
  fclose(rsi_last_mac);
  return RSI_STATUS_SUCCESS;
}

/**********************************************************************
 * Read the value of config parameters
 * ********************************************************************/
int rsi_get_token(FILE *info_file, const char *check_str, char *res)
{
  char temp[1024];
  char *start;

  fseek(info_file,0,SEEK_SET);
  while(!feof(info_file))
  {
    fscanf(info_file,"%s",temp);
    start = temp; /* skip all  spaces */
    while(isspace(*start)) start++;
    if((start[0] == '/') && (start[1] == '/'))
    {
      continue;
    }
    if((start = strstr(start,check_str)))
    {
      start+=strlen(check_str);
      start++;/* skip = */
      strcpy(res,start);
      return RSI_STATUS_SUCCESS;
    }
  }
  printf("\nWARNING ERROR IN READING CONFIG FILE.... SOME CONFIGURATIONS MISSING\n");
  return RSI_STATUS_FAILURE;
}

/**********************************************************************
 * Read config file parameters
 * ********************************************************************/
int rsi_read_config(void)
{
  char token[80];
  FILE *rsi_config, *rsi_last_mac;
  
  rsi_config = fopen("RSI_Config.txt","r");
  rsi_last_mac = fopen("RSI_LastMac.txt","rw");
    
  if (rsi_last_mac == NULL) 
  {
    printf("Unable to open LAST MAC file\n");
    if (rsi_config == NULL)
    {
      printf("Unable to open CONFIG file\n");
      return RSI_STATUS_FAILURE;
    }  
  }  
  if (rsi_get_token(rsi_config,"RSI_VENDOR_ID",token) != RSI_STATUS_SUCCESS)
    return RSI_STATUS_FAILURE;
    
  
  sscanf(token,"%x",&test_params.vendor_id);
  printf("Vebdor ID %x\n",test_params.vendor_id);
  
  //get last Mac Id from LiteFiLastMac.txt
  if (rsi_get_token(rsi_last_mac,"RSI_LAST_WLAN_MAC_ID",token) != RSI_STATUS_SUCCESS)
    return RSI_STATUS_FAILURE;
  sscanf(token,"%x",&test_params.wlan_mac_id);
  printf("WLAN MAC ID %x\n",test_params.wlan_mac_id);
 
  if (rsi_get_token(rsi_last_mac,"RSI_LAST_BT_MAC_ID",token) != RSI_STATUS_SUCCESS)
    return RSI_STATUS_FAILURE;
  sscanf(token,"%x",&test_params.bt_mac_id);
  printf("BT MAC ID %x\n",test_params.bt_mac_id);
  
  if (rsi_get_token(rsi_last_mac,"RSI_LAST_ZIGBEE_MAC_ID",token) != RSI_STATUS_SUCCESS)
    return RSI_STATUS_FAILURE;
  sscanf(token,"%x",&test_params.zigbee_mac_id);
  printf("ZIGBEE MAC ID %x\n",test_params.zigbee_mac_id);
  
//  memcpy(&test_params.wlan_mac_id , ,sizeof(token));

#if 1
  if (rsi_get_token(rsi_config,"RSI_WLAN_START_MAC_ID",token) != RSI_STATUS_SUCCESS)
    return RSI_STATUS_FAILURE;
  sscanf(token,"%x",&test_params.start_mac_id);
  printf("WLAN START MAC ID %x\n",test_params.start_mac_id);
  
  if (rsi_get_token(rsi_config,"RSI_WLAN_END_MAC_ID",token) != RSI_STATUS_SUCCESS)
    return RSI_STATUS_FAILURE;
  sscanf(token,"%x",&test_params.end_mac_id);
  printf("WLAN END MAC ID %x\n",test_params.end_mac_id);
#endif  
  if (rsi_get_token(rsi_config,"RSI_NUM_OF_WLAN_MAC_IDS",token) != RSI_STATUS_SUCCESS)
    return RSI_STATUS_FAILURE;
  sscanf(token,"%x",&test_params.num_wlan_macs);
  printf("NUM OF WLAN MAC ID's %x\n",test_params.num_wlan_macs);
  
  if (rsi_get_token(rsi_config,"RSI_BT_START_MAC_ID",token) != RSI_STATUS_SUCCESS)
    return RSI_STATUS_FAILURE;
  sscanf(token,"%x",&test_params.bt_start_mac_id);
  printf("BT START MAC ID %x\n",test_params.bt_start_mac_id);
  
  if (rsi_get_token(rsi_config,"RSI_BT_END_MAC_ID",token) != RSI_STATUS_SUCCESS)
    return RSI_STATUS_FAILURE;
  sscanf(token,"%x",&test_params.bt_end_mac_id);
  printf("BT END MAC ID %x\n",test_params.bt_end_mac_id);
  

  if (rsi_get_token(rsi_config,"RSI_ZIGBEE_START_MAC_ID",token) != RSI_STATUS_SUCCESS)
    return RSI_STATUS_FAILURE;
  sscanf(token,"%x",&test_params.zigbee_start_mac_id);
  printf("ZIGBEE START MAC ID %x\n",test_params.zigbee_start_mac_id);
  
  if (rsi_get_token(rsi_config,"RSI_ZIGBEE_END_MAC_ID",token) != RSI_STATUS_SUCCESS)
    return RSI_STATUS_FAILURE;
  sscanf(token,"%x",&test_params.zigbee_end_mac_id);
  printf("ZIGBEE END MAC ID %x\n",test_params.zigbee_end_mac_id);
  
  if (rsi_get_token(rsi_config,"RSI_FLASH_SIZE",token) != RSI_STATUS_SUCCESS)
    return RSI_STATUS_FAILURE;
  sscanf(token,"%x",&test_params.flash_size);
  printf("flash_size %x\n",test_params.flash_size);
  
  fclose(rsi_last_mac);
  fclose(rsi_config);
  return RSI_STATUS_SUCCESS;
}
