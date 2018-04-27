#!/usr/bin/env python
#coding:utf-8


import time
import sys
# reload(sys)
# sys.setdefaultencoding('utf-8')

import os
import datetime

import socket
import fcntl
import struct
import logging

import time, threading
import tornado.ioloop
import tornado.options
import tornado.web
import tornado.httpserver

from tornado.options import define,options
from tornado.websocket import WebSocketHandler
# from traceback import print_exc
import dbus
import dbus.decorators
import dbus.glib
from gi.repository import GLib
# from handler.index import GL

import json

class MyClass_json:
    #初始化
    def __init__(self):
        self.name_cmd=" "
        self.list_data=[]

def send_message_to_html(message,item_list):
    for handler in item_list.socket_handlers:
        try:
            handler.write_message(message)
        except:
            logging.error('Error sending message', exc_info=True)

class mainloop_class():

    def __init__(self):
        self.mainloop = GLib.MainLoop()

    def mainloop_run(self):
        self.mainloop.run()

    def mainloop_quit(self):
        self.mainloop.quit()

## dbus base
class BaseMessage_DBus():
    connect_statu=1
    dbus_name="com.myirtech.mxde"
    dbus_path= "/com/myirtech/mxde"
    dbus_interface="com.myirtech.mxde.MxdeInterface"

    path_file='/usr/share/myir/board_cfg.json'
    try:
        file=open(path_file, 'r')
        f_read = json.load(file)
    except:
        print("Did not find the configuration file '/usr/share/myir/board_cfg.json' ")
    finally:
        pass

    try:
        dbus_name=f_read["dbus_info"]["dbus_name"]
        dbus_path=f_read["dbus_info"]["dbus_path"]
        dbus_interface=f_read["dbus_info"]["dbus_interface"]
    except:
         print ("read dbus configure error")

    bus=dbus.SessionBus()
    iface = dbus.Interface("test",dbus_interface)
    # def __init__(self):
    #     pass
    #     print "init dbus"

    # def connect_dbus(self):
    try:
        print("try dbus connect !!!")
        remote_object = bus.get_object(dbus_name, dbus_path)
        iface = dbus.Interface(remote_object, dbus_interface)
    except dbus.DBusException:
        # traceback.print_exc()
        print("dbus get object error !")
        connect_statu=0

    if connect_statu==1:
        print("dbus connect succless !")
    else:
        print("dbus connect faild !")

    # mainloop = GLib.MainLoop()

    def __init__(self):
        try:
            print("try dbus connect 2!")
            remote_object = self.bus.get_object(self.dbus_name, self.dbus_path)
            self.iface = dbus.Interface(remote_object, self.dbus_interface)

        except dbus.DBusException:
            # traceback.print_exc()
            print("dbus get object error ")

    def manloop(self):
        self.mainloop = GLib.MainLoop()
        self.mainloop.run()

    # def r_run(self):
    #     self.mainloop = GLib.MainLoop()
    #     self.mainloop.run()

    # def r_quit(self):
    #     self.mainloop.quit()

def str_operate(fd,str_input,fun):
    MAX_LEN=30
    # integer_str_num=0
    # remainder_str_num=0
    temp_fd = dbus.Int16(fd)
    str_len = len(str_input)
    integer_str_num = str_len / MAX_LEN
    remainder_str_num = str_len % MAX_LEN

    for i in range(0, integer_str_num, 1):
        start_pos = i * MAX_LEN
        end_pos = i * MAX_LEN + MAX_LEN
        temp_str = str_input[start_pos:end_pos]
        # temp_fd=dbus.Int16(fd)
        temp_data_buf = dbus.String(temp_str)

        temp_buff_size=dbus.Int16(MAX_LEN)
        fun(temp_fd,temp_data_buf,temp_buff_size)
    if remainder_str_num>0:
        temp_str = str_input[integer_str_num * MAX_LEN:integer_str_num * MAX_LEN + remainder_str_num]
        temp_data_buf = dbus.String(temp_str)
        temp_buff_size = dbus.Int16(remainder_str_num)
        fun(temp_fd, temp_data_buf, temp_buff_size)

class str_intercept():
    MAX_LEN=30
    integer_str_num=0
    remainder_str_num=0
    def __init__(self):
        pass
    def ret_str(self,str_input):
        str_len=len(str_input)
        self.integer_str_num=str_len/self.MAX_LEN
        self.remainder_str_num=str_len%self.MAX_LEN
        for i in range(0,self.integer_str_num,1):
            start_pos=i*self.MAX_LEN
            end_pos=i*self.MAX_LEN+self.MAX_LEN-1
            temp_str=str_input[start_pos:end_pos]
            # print temp_str
            # return temp_str
## led
class dbus_led(BaseMessage_DBus):

    def __init__(self):
        pass

    def add_signal_call(self):
        # pass
        BaseMessage_DBus.bus.add_signal_receiver(self.led_recv_data, dbus_interface=BaseMessage_DBus.dbus_interface, \
                                                 bus_name=BaseMessage_DBus.dbus_name, path=BaseMessage_DBus.dbus_path, \
                                                 signal_name="sigLedBrightnessChanged")

    def _message_led(self,temp_str,list_va):
        from handler.index import WebSocketHandler_myir
        configure_data = MyClass_json()
        configure_data.name_cmd = "led_recv_data"
        configure_data.data_buff = temp_str
        configure_data.list_va = list_va
        configure_data_json = configure_data.__dict__
        json_data = json.dumps(configure_data_json)
        send_message_to_html(json_data, WebSocketHandler_myir)

    def led_recv_data(self, str_led):
        self._message_led(str_led,0)

    def led_list(self):
        str_led = BaseMessage_DBus.iface.getLedList()
        self._message_led(str_led,1)

    def led_set(self,led_name,val):
        temp_name=dbus.String(led_name)
        temp_value=dbus.Int16(val)
        # dbus.Int16
        BaseMessage_DBus.iface.setLedBrightress(temp_name,temp_value)
        return True

## uart
class dbus_uart(BaseMessage_DBus):

    def __init__(self):
        pass

    def add_signal_call(self):
        # pass
        BaseMessage_DBus.bus.add_signal_receiver(self.serial_recv_data, dbus_interface=BaseMessage_DBus.dbus_interface, \
                                                 bus_name=BaseMessage_DBus.dbus_name, path=BaseMessage_DBus.dbus_path, \
                                                 signal_name="sigSerialRecv")

    def serial_recv_data(self, fd, data, len):
            from handler.index import WebSocketHandler_myir
            temp_fd = fd
            temp_data = data

            configure_data = MyClass_json()
            from handler.index import GL

            if GL.fd_tty232 == temp_fd:
                if GL.fd_tty232>0:
                    configure_data.name_cmd = "rs232_recv_data"
                else:
                    configure_data.name_cmd = "null"
                    return
            elif GL.fd_tty485 == temp_fd:
                if GL.fd_tty485>0:
                    configure_data.name_cmd = "rs485_recv_data"
                else:
                    configure_data.name_cmd = "null"
                    return
            else:
                configure_data.name_cmd = "null"
                return

            # if configure_data.name_cmd=="nill":
            #     return

            configure_data.data_buff = temp_data
            configure_data_json = configure_data.__dict__
            json_data = json.dumps(configure_data_json)
            send_message_to_html(json_data, WebSocketHandler_myir)

    ## 串口的相关函数
    def serial_open(self,tty_name):
        temp = dbus.String(tty_name)
        # serial_fd=BaseMessage_DBus.iface.openSerialPort(temp)

        '''
        char device_name,int fd, int bitrate, int datasize, int mode, int flow, char * par, int stop
        '''
        serial_fd, temp_param = BaseMessage_DBus.iface.openSerialPort(temp)
        # if serial_fd==0:
        #     serial_param = temp_param.split()
        #     return serial_fd,serial_param ## 串口的状态是已经打开的

        temp_ret=int(serial_fd)
        return temp_ret,temp_param

    def serial_close(self,tty_fd):
        temp = dbus.Int16(tty_fd)
        BaseMessage_DBus.iface.closeSerialPort(temp)
        # return serial_fd

    def serial_send_data(self,fd,data,num):
        temp_fd=dbus.Int16(fd)
        temp_data_buf = dbus.String(data)
        # temp_num=dbus.Int16(num)
        # BaseMessage_DBus.iface.SerialWrite(temp_fd,temp_data_buf,temp_num)
        str_operate(temp_fd,temp_data_buf,BaseMessage_DBus.iface.SerialWrite)

    def serial_set_parameter(self,fd,bitrate,datasize,mode,flow,par,stop):
        temp_fd =   dbus.String(fd)
        temp_baudrate= dbus.String(bitrate)
        temp_datasize = dbus.String(datasize)
        temp_mode =   dbus.String(mode)
        temp_flow = dbus.String(flow)
        temp_par = dbus.String(par)
        temp_stop = dbus.String(stop)
        temp_all=temp_fd+" "+temp_baudrate+" "+temp_datasize+" "+temp_mode+" "+temp_flow+" "+temp_par+" "+temp_stop
        BaseMessage_DBus.iface.setSerialPort(temp_all)

## can
class dbus_can(BaseMessage_DBus):

    def __init__(self):
        pass
    def add_signal_call(self):
        # pass
        BaseMessage_DBus.bus.add_signal_receiver(self.can_recv_data, dbus_interface=BaseMessage_DBus.dbus_interface, \
                                                 bus_name=BaseMessage_DBus.dbus_name, path=BaseMessage_DBus.dbus_path, \
                                                 signal_name="sigCanRecv")

    def can_recv_data(self, fd, can_id, len,can_data):
        from handler.index import WebSocketHandler_myir
        configure_data = MyClass_json()
        from handler.index import GL

        if GL.fd_can>0:
            configure_data.name_cmd = "can_recv_data"
            configure_data.data_buff = can_data
            configure_data.data_id = int(can_id)
            configure_data_json = configure_data.__dict__
            json_data = json.dumps(configure_data_json)
            send_message_to_html(json_data, WebSocketHandler_myir)
## can
    def can_open(self,can_name):
        temp = dbus.String(can_name)
        can_fd=BaseMessage_DBus.iface.openCanPort(temp)
        tmp = int(can_fd)
        return tmp

    def can_close(self,can_name,fd):
        temp = dbus.String(can_name)
        temp_fd = dbus.Int16(fd)
        BaseMessage_DBus.iface.closeCanPort(temp,temp_fd)

    def can_close_loop(self,can_name,fd):
        temp_name = dbus.String(can_name)
        temp_fd = dbus.Int16(fd)
        BaseMessage_DBus.iface.closeCanLoop(temp_name, temp_fd)

    def can_set_parameter(self,can_name,baud_rates,status,loop):
        baud_rates_1=int(baud_rates)*1000
        temp_name = dbus.String(can_name)
        temp_baud_rates = dbus.Int64(baud_rates_1)
        temp_baud_status = dbus.Int16(status)
        temp_loop = dbus.String(loop)
        #temp_ret=BaseMessage_DBus.iface.setCanPort(temp_name, temp_baud_rates,temp_baud_status,temp_loop)

        '''
        <arg name="can_configure" type="s" direction="out"/> 
        char *device_name, int fd, int bitrate, char  *loop
        '''
        tmp_ret,temp_param= BaseMessage_DBus.iface.setCanPort(temp_name, temp_baud_rates, temp_baud_status, temp_loop)
        temp_ret=int(tmp_ret)
        return temp_ret, temp_param

    def can_send_data(self,fd,data,num):
        temp_fd = dbus.Int16(fd)
        temp_data = dbus.String(data)
        # temp_num = dbus.Int16(num)
        # BaseMessage_DBus.iface.CanWrite(temp_fd,temp_data,temp_num)
        str_operate(temp_fd, temp_data, BaseMessage_DBus.iface.CanWrite)
