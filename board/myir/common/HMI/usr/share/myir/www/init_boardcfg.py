#!/bin/sh
# coding=utf-8  
import os,sys  
import json 
from itertools import islice

from collections import OrderedDict

def cmdline_read():
    rel=' '
    str_param='rootfstype='
    len_str_check=len(str_param)
    f = open("/proc/cmdline")
    lines = f.readlines()
    print lines[0]
    read_param=lines[0].split(' ')
    #read_param=sr.split(' ')
    for i in range(0,len(read_param)):
        if read_param[i][0:len_str_check]=="rootfstype=":
            # print read_param[i][len_str_check:]
            rel=read_param[i][len_str_check:]
    # f.close()
    return rel

def get_new_json(filepath, mem, storage):  
    with open(filepath, 'rb') as f:  
        json_data = json.load(f,object_pairs_hook=OrderedDict)  
        json_data["board_info"]["system"]['memory']= mem
        json_data["board_info"]["system"]['storage']= storage
    f.close()  
    return json_data  

def get_mem_size():
	s = 0
	info = open("/proc/meminfo")
	for line in info:
		t = line.split()[0]
		s = line.split()[1]
		if 'MemTotal' in t :
			break
	s = int(s)/1024
	if s <= 256 :
		s = 256
	elif s <= 512 :
		s = 512
	elif s <= 1024 :
		s = 1024

	return str(s)+'MB'

def get_nand_size():
	sum = 0
	parts =  open("/proc/partitions")
	
	for line in islice(parts,2,None):
		t = line.split()[3]
		s = line.split()[2]
		if 'mtdblock' in t :
			sum = sum + int(s)
	sum = sum/1024
	return str(sum)+'MB'
	
def rewrite_json_file(filepath,json_data):  
    with open(filepath, 'w') as f:
        json.dump(json_data,f,ensure_ascii=False,indent=2)  
    f.close()  
  
if __name__ == '__main__':
    json_path = '/usr/share/myir/board_cfg.json'
    if 'ext4'==cmdline_read():
        m_json_data = get_new_json(json_path, "512MB", "4GB")   
        rewrite_json_file(json_path,m_json_data) 
    else:
	s = get_nand_size()
	m = get_mem_size()
	m_json_data = get_new_json(json_path, m , s)
	rewrite_json_file(json_path, m_json_data)
        pass
