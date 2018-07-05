#!/usr/bin/env python
#coding:utf-8

import tornado.websocket  
import tornado.web
import tornado.ioloop
import tornado.httpserver
import tornado.options
import os
import datetime

import socket
import fcntl
import struct
import logging
import time, threading
from time import ctime,sleep
# import simplejson as json
import json
from tornado.web import RequestHandler
from tornado.options import define, options
from tornado.websocket import WebSocketHandler
import traceback
from gi.repository import GLib
import dbus
import dbus.mainloop.glib
from handler.connman import ConnmanClient
# from traceback import print_exc
# import dbus.decorators
# import dbus.glib
from handler.dbus_mess import MyClass_json
from handler.dbus_mess import send_message_to_html
from handler.dbus_mess import dbus_uart
from handler.dbus_mess import dbus_can
from handler.dbus_mess import dbus_led
from handler.ping import verbose_ping_2
from handler.ping import judge_legal_ip2

# import pylibmc
import ctypes
from ctypes import *
import sys
# reload(sys)
# sys.setdefaultencoding('utf-8')

class MyGlobal:
    def __init__(self):
        # self.A = 0
        # self.B = [0]
        self.fd_tty485 = -1
        self.fd_tty232 = -1
        self.fd_can = -1
        self.fd_can_name = "can0"
        self.net_name="net1"
        self.net_change=0

GL = MyGlobal()

# def get_ip_address(ifname):
#     s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
#     return socket.inet_ntoa(fcntl.ioctl(
#         s.fileno(),
#         0x8915,  # SIOCGIFADDR
#         struct.pack('256s', ifname[:15])
#     )[20:24])

def get_ip_address(ifname):
  import socket, fcntl, struct
  s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
  inet = fcntl.ioctl(s.fileno(), 0x8915, struct.pack('256s', ifname[:15]))
  ret = socket.inet_ntoa(inet[20:24])
  return ret

class Parse_command():
    uart_dbus_call = dbus_uart()
    can_dbus_call = dbus_can()
    led_dbus_call = dbus_led()
    uart_dbus_call.add_signal_call()
    can_dbus_call.add_signal_call()
    led_dbus_call.add_signal_call()
    status_data = MyClass_json()
    status_data.name_cmd = "status_data"

    def baudrate_get(self,tmp1):
        tmp=str(tmp1)
        if tmp=="300":
            return 1
        elif tmp=="600":
            return 2
        elif tmp=="1200":
            return 3
        elif tmp=="2400":
            return 4
        elif tmp=="4800":
            return 5
        elif tmp=="9600":
            return 6
        elif tmp=="19200":
            return 7
        elif tmp=="38400":
            return 8
        elif tmp=="57600":
            return 9
        elif tmp=="115200":
            return 10

    def databit_get(self,tmp1):
        tmp = str(tmp1)
        if tmp == "8":
            return 1
        elif tmp == "7":
            return 2
        elif tmp == "6":
            return 3

    def check_get(self,tmp1):
        tmp = str(tmp1)
        if tmp == "NONE":
            return 1
        elif tmp == "EVEN":
            return 2
        elif tmp == "ODD":
            return 3

    def stop_get(self,tmp1):
        tmp = str(tmp1)
        if tmp == "1":
            return 1
        elif tmp == "2":
            return 2

    def can_loop_get(self,tmp1):
        tmp=str(tmp1)
        if tmp=="OFF":
            return 1
        elif tmp=="ON":
            return 2

    def can_baudrate_get(self, tmp1):
        tmp=str(tmp1)
        if tmp=="20000":
            return 1
        elif tmp=="50000":
            return 2
        elif tmp=="125000":
            return 3
        elif tmp=="250000":
            return 4
        elif tmp=="500000":
            return 5
        elif tmp=="800000":
            return 6
        elif tmp=="1000000":
            return 7

    def serial_rs232_handler(self,python_object,dbus_call_t):
        uart_control = python_object["control"]
        if uart_control == 0:  # close
            # uart_name = python_object["name"]
            dbus_call_t.serial_close(GL.fd_tty232)
            GL.fd_tty232 = -1
        elif uart_control == 1:  # open
            uart_name = python_object["name"]
            self.status_data.name_status = "rs232_status"

            #GL.fd_tty232 = dbus_call_t.serial_open(uart_name)
            tmp_value,tmp_param = dbus_call_t.serial_open(uart_name)
            temp_param = tmp_param.split(" ")

            if tmp_value == 0:
                GL.fd_tty232 = int(temp_param[1])
                self.status_data.status_rdy = 1
                self.status_data.status_operation = "successed"
                self.status_data.baudrate_1 = self.baudrate_get(temp_param[2])
                self.status_data.databit_1 = self.databit_get(temp_param[3])
                self.status_data.captbit_1 = self.check_get(temp_param[6])
                self.status_data.stopbit_1 = self.stop_get(temp_param[7])
            else:
                if tmp_value > 0:
                    GL.fd_tty232 = tmp_value
                    self.status_data.status_rdy = 0
                    baudrate = python_object["baud_rate"]
                    databit = python_object["databit"]
                    stopbit = python_object["stopbit"]
                    captbit = python_object["checkbit"]
                    dbus_call_t.serial_set_parameter(GL.fd_tty232, baudrate, databit, 0, 0, captbit, stopbit)
                    self.status_data.status_operation = "successed"
                else:
                    self.status_data.status_operation = "faild"
                    GL.fd_tty232=-1
##  旧的
            # if GL.fd_tty232>0:
            #     baudrate = python_object["baud_rate"]
            #     databit = python_object["databit"]
            #     stopbit = python_object["stopbit"]
            #     captbit = python_object["checkbit"]
            #     dbus_call_t.serial_set_parameter(GL.fd_tty232, baudrate, databit, 0, 0, captbit, stopbit)
            #     self.status_data.status_operation = "successed"
            # else:
            #     self.status_data.status_operation = "faild"

            self.status_data_data = self.status_data.__dict__
            self.status_json = json.dumps(self.status_data_data)
            send_message_to_html(self.status_json, WebSocketHandler_myir)
            # 添加反馈信息到html

        # elif uart_control == 2:  # set
        #     baudrate = python_object["baud_rate"]
        #     databit = python_object["databit"]
        #     stopbit = python_object["stopbit"]
        #     captbit = python_object["checkbit"]
        #     dbus_call_t.serial_set_parameter(GL.fd_tty232, baudrate, databit, 0, 1, captbit, stopbit)
        elif uart_control == 3:  # send
            buf_data = python_object["buf_data"]
            dbus_call_t.serial_send_data(GL.fd_tty232, buf_data, len(buf_data))
        else:
            pass

    def serial_rs485_handler(self,python_object,dbus_call_t):
        uart_control = python_object["control"]
        if uart_control == 0:  # close
            # uart_name = python_object["name"]
            dbus_call_t.serial_close(GL.fd_tty485)
            GL.fd_tty485 = -1
        elif uart_control == 1:  # open
            uart_name = python_object["name"]
## 旧的
            # GL.fd_tty485 = dbus_call_t.serial_open(uart_name)
            # self.status_data.name_status = "rs485_status"
            # if GL.fd_tty485 > 0:
            #     baudrate = python_object["baud_rate"]
            #     databit = python_object["databit"]
            #     stopbit = python_object["stopbit"]
            #     captbit = python_object["checkbit"]
            #     dbus_call_t.serial_set_parameter(GL.fd_tty485, baudrate, databit, 1, 1, captbit, stopbit)
            #     self.status_data.status_operation = "successed"
            # else:
            #     self.status_data.status_operation = "faild"

            self.status_data.name_status = "rs485_status"
            #GL.fd_tty485 = dbus_call_t.serial_open(uart_name)
            tmp_value,tmp_param = dbus_call_t.serial_open(uart_name)
            temp_param = tmp_param.split(" ")
            if tmp_value== 0:    ##
                GL.fd_tty485 = int(temp_param[1])
                self.status_data.status_rdy = 1
                self.status_data.status_operation = "successed"
                # self.status_data.baudrate = baudrate
                # self.status_data.databit = databit
                # self.status_data.captbit = captbit
                # self.status_data.stopbit = stopbit
                self.status_data.baudrate_1 = self.baudrate_get(temp_param[2])
                self.status_data.databit_1 = self.databit_get(temp_param[3])
                self.status_data.captbit_1 = self.check_get(temp_param[6])
                self.status_data.stopbit_1 = self.stop_get(temp_param[7])
            else:
                if tmp_value > 0:
                    GL.fd_tty485 = tmp_value
                    self.status_data.status_rdy = 0
                    baudrate = python_object["baud_rate"]
                    databit = python_object["databit"]
                    stopbit = python_object["stopbit"]
                    captbit = python_object["checkbit"]
                    dbus_call_t.serial_set_parameter(GL.fd_tty485, baudrate, databit, 1, 0, captbit, stopbit)
                    self.status_data.status_operation = "successed"
                else:
                    self.status_data.status_operation = "faild"
                    GL.fd_tty485=-1

            self.status_data_data = self.status_data.__dict__
            self.status_json = json.dumps(self.status_data_data)
            send_message_to_html(self.status_json, WebSocketHandler_myir)
            # elif uart_control == 2:  # set
            #     baudrate = python_object["baud_rate"]
            #     databit = python_object["databit"]
            #     stopbit = python_object["stopbit"]
            #     captbit = python_object["checkbit"]
            #     dbus_call_t.serial_set_parameter(GL.fd_tty485, baudrate, databit, 1, 0, captbit, stopbit)
        elif uart_control == 3:  # send
            buf_data = python_object["buf_data"]
            dbus_call_t.serial_send_data(GL.fd_tty485, buf_data, len(buf_data))
        else:
            pass

    def can_handler(self,python_object,dbus_call_t):
        can_name = python_object["name"]
        GL.fd_can_name =can_name
        # can_id = python_object["can_id"]
        can_control = python_object["control"]

        if can_control == 0:    # close
            # dbus_call_t.can_set_parameter(can_name, baudrate, 0, can_loop)
            dbus_call_t.can_close(can_name, GL.fd_can)
            GL.fd_can = -1
        elif can_control == 1:  # open

         #   if GL.fd_can>0:
         #       dbus_call_t.can_close(can_name, GL.fd_can)
         #       GL.fd_can = 0

    ##  旧版本
            # dbus_call_t.can_set_parameter(can_name, baudrate, 1, can_loop)
            # GL.fd_can = dbus_call_t.can_open(can_name)  # get can id

            # if GL.fd_can>0:
            #     baudrate = python_object["baud_rate"]
            #     self.status_data.name_status = "can_status"
            #     # sendbuff_len = python_object["can_len_sendbuff"]
            #     dbus_call_t.can_set_parameter(can_name, baudrate, 1, can_loop)
            #     self.status_data.status_operation = "successed"
            # else:
            #     self.status_data.status_operation = "faild"

            can_loop = python_object["can_loop"]
            baudrate = python_object["baud_rate"]
            self.status_data.name_status = "can_statuss"
            tmp_value,tmp_param=dbus_call_t.can_set_parameter(can_name, baudrate, 1, can_loop)
            # temp_param = tmp_param.split(" ")
            if tmp_value==100:   ##  已经是打开状态
                # GL.fd_can = dbus_call_t.can_open(can_name)
                can_param = tmp_param.split(" ")
                GL.fd_can = int(can_param[1])
                baudrate = can_param[2]
                can_loop = can_param[3]

                self.status_data.status_rdy = 1
                self.status_data.status_operation = "successed"
                self.status_data.baudrate_1 = self.can_baudrate_get(baudrate)
                self.status_data.can_loop_1 = self.can_loop_get(can_loop)
                # self.status_data.fd_can = can_loop
                self.status_data.name_can_1 = str(can_param[0])
            else:
                self.status_data.status_rdy = 0
                GL.fd_can = dbus_call_t.can_open(can_name)
                if GL.fd_can<0:
                    self.status_data.status_operation = "faild"
                else:
                    self.status_data.status_operation = "successed"

            self.status_data_data = self.status_data.__dict__
            self.status_json = json.dumps(self.status_data_data)
            send_message_to_html(self.status_json, WebSocketHandler_myir)

        elif can_control == 2:  # set
            can_loop = python_object["can_loop"]
            baudrate = python_object["baud_rate"]
            # sendbuff_len = python_object["can_len_sendbuff"]
            dbus_call_t.can_set_parameter(can_name, baudrate, 1, can_loop)
        elif can_control == 3:  # send
            buf_data = python_object["buf_data"]
            can_id = python_object["can_id"]
            buf_send=str(can_id)+"+"+buf_data
            self.can_dbus_call.can_send_data(GL.fd_can, buf_send, len(buf_data))
        else:
            pass

    def led_handler(self,python_object,dbus_call_t):
        led_name = python_object["name"]
        if led_name=="led_list":
            dbus_call_t.led_list()
        else:
            led_value_set = python_object["value_set"]
            if led_value_set==3:
                return
            dbus_call_t.led_set(led_name,led_value_set)
    def eth_handler(self,python_object):
        eth_op=class_eth()
        eth_op.init_connmanclient()
        eth_name = python_object["name"]
        eth_control=python_object["control"]
        if eth_control==1:   # 设置IP  connman的库有bug，使用
            ip_eth = python_object["dest_addr"]
            ip_netmask = python_object["dest_netmask"]
            ip_gateway = python_object["dest_gateway"]

            # str_config = "ifconfig " + eth_name + " "+ip_eth
            # os.system(str_config)

            # if ip_netmask==" ":
            #     print "IP parameter is incomplete"
            #     return
            # if str(ip_gateway) == " ":
            #     print "IP parameter is incomplete"
            #     return
            # if ip_eth == " ":
            #     print "IP parameter is incomplete"
            #     return
            # if eth_name == " ":
            #     print "IP parameter is incomplete"
            #     return

            eth_op.myConn.set_ipv4(ip_netmask,ip_gateway,"manual",ip_eth,eth_name)

            if(str(eth_name)==str(GL.net_name)):
                time.sleep(1)
                os.system(" reboot ")
            # read and sent to html
            # eth_op._eth_handler_to_sent()
        elif eth_control==2:   ## 自动获取ip  
            # str_config = "udhcpc -i " + eth_name
            # os.system(str_config)
            eth_op.myConn.set_ipv4_dhcp("dhcp",eth_name)
            time.sleep(1)
            eth_op._eth_handler_to_sent()
        elif eth_control==3:   ##  ping 测试
            ping_ip=python_object["ping_addr"]
            #if judge_legal_ip2(ping_ip):
            for i in range(10):
                ping_log=verbose_ping_2(ping_ip,2)
                eth_data = MyClass_json()
                eth_data.name_cmd = "eth_data"
                eth_data.control="ping"
                eth_data.eth_name=eth_name
                eth_data.ping_data=ping_log
                eth_json_data = eth_data.__dict__
                eth_json = json.dumps(eth_json_data)
                send_message_to_html(eth_json, WebSocketHandler_myir)
                
    def update_eth_info(self):
        eth_op = class_eth()
        eth_op.init_connmanclient()
        # eth_op._eth_handler_to_sent()
        # sleep(0.5)
        eth_op._eth_handler_to_sent()

    def parse_c(self,message):
        python_object = json.loads(message)
        cmd = python_object["cmd"]
        if cmd == "uart_cmd":
            self.serial_rs232_handler(python_object,self.uart_dbus_call)
        elif cmd == "uart485_cmd":
            self.serial_rs485_handler(python_object,self.uart_dbus_call)
        elif cmd == "can_cmd":
            self.can_handler(python_object,self.can_dbus_call)
        elif cmd == "led_cmd":
            self.led_handler(python_object,self.led_dbus_call)
        elif cmd == "eth_cmd":
            self.eth_handler(python_object)
        elif cmd == "eth_cmd_upate":
            self.update_eth_info()

def read_configure():
    path_file='/usr/share/myir/board_cfg.json'
    try:
        file=open(path_file, 'r')
        f_read = json.load(file)
    except:
        print("Did not find the configuration file '/usr/share/myir/board_cfg.json' ")
    finally:
        pass
    try:
        rs232_port="/dev/"+f_read["board_info"]['rs232'][0]
        rs485_port="/dev/"+f_read["board_info"]['rs485'][0]
        can_port=f_read["board_info"]['can'][0]
        # can_port1=f_read["board_info"]['can'][1]
        # eth0_port=f_read['board_info']['eth0_port']

        # GL.dbus_name=f_read["dbus_info"][0]
        # GL.dbus_path=f_read["dbus_info"][1]
        # GL.dbus_interface=f_read["dbus_info"][2]
    except:
        print ("read board_cfg.json error")
        return 0
    return rs232_port,rs485_port,can_port

def read_configure_tt():
    list_232_port = []
    list_485_port = []
    list_can_port = []
    path_file='/usr/share/myir/board_cfg.json'
    try:
        file=open(path_file, 'r')
        f_read = json.load(file)
    except:
        print("Did not find the configuration file '/usr/share/myir/board_cfg.json' ")
    finally:
        pass
    try:
        rs232_port = f_read["board_info"]['rs232']
        rs485_port = f_read["board_info"]['rs485']
        can_port = f_read["board_info"]['can']
        count_rs232 = len(rs232_port)
        count_rs485 = len(rs485_port)
        count_can = len(can_port)
        ##  data
        for i in range(count_rs232):
            list_232_port.append(rs232_port[i])  ## 232
        for i in range(count_rs485):
            list_485_port.append(rs485_port[i])  ## 485
        for i in range(count_can):
            list_can_port.append(can_port[i])    ## can
    except:
        print ("read board_cfg.json error")
        return 0

    return list_232_port,list_485_port,list_can_port

# class read_configure_file():
#
#     def __init__(self):
#         pass
#
#     def read_configure(self):
#         path_file = '/usr/share/myir/board_cfg.json'
#         file=open(path_file, 'r')
#         f_read = json.load(file)
#
#         try:
#             rs232_port = f_read["board_info"]['rs232'][0]
#             rs485_port = f_read["board_info"]['rs485'][0]
#             can_port = f_read["board_info"]['can'][0]
#         except:
#             print ("read board_cfg.json error")
#
#         return rs232_port,rs485_port,can_port

def make_string(str):
    return dbus.String(str, variant_level=1)


class port_json:
    #初始化
    def __init__(self):
        self.name_cmd=" "
        self.list_232_port=[]
        self.list_485_port=[]
        self.list_can_port=[]

class WebSocketHandler_myir(tornado.websocket.WebSocketHandler):
    socket_handlers = set()
    mess_t = Parse_command()

    def check_origin(self, origin):
        return True

    def open(self):
        # print ("websocket opened")
        WebSocketHandler_myir.socket_handlers.add(self)
        eth_operate = class_eth()
        eth_operate.init_connmanclient()
        ## init
        # rs232_port, rs485_port, can_port=read_configure()
        configure_data = MyClass_json()
        configure_data.name_cmd="configure_cmd"
        configure_data.list_232_port,configure_data.list_485_port,configure_data.list_can_port = read_configure_tt()
        configure_data.web_net_using=str(GL.net_name)
        # configure_data.eth0_port=eth0_port
        configure_data_json = configure_data.__dict__
        json_data = json.dumps(configure_data_json)
        send_message_to_html(json_data, WebSocketHandler_myir)
        eth_operate._eth_handler_to_sent()
        # sleep(0.5)
        # eth_operate._eth_handler_to_sent()

    def on_message(self, message):
        self.mess_t.parse_c(message)
        return

    def on_close(self):
        # print ('websocket closed')
        if  GL.fd_tty485>0:
            self.mess_t.uart_dbus_call.serial_close(GL.fd_tty485)
            GL.fd_tty485=-1
        if  GL.fd_tty232>0:
            self.mess_t.uart_dbus_call.serial_close(GL.fd_tty232)
            GL.fd_tty232=-1
        if  GL.fd_can>0:
            self.mess_t.can_dbus_call.can_close(GL.fd_can_name,GL.fd_can)
            GL.fd_can=-1
        WebSocketHandler_myir.socket_handlers.remove(self)

class class_eth():

    def __init__(self):
        # self.myConn = ConnmanClient(90)
        pass

    def init_connmanclient(self):
        self.myConn = ConnmanClient(90)

    def _eth_handler_to_sent(self):
        ##read status and connect
        cnt , list_services_info = self.myConn.get_services_info()
        for i in range(cnt):
            if (list_services_info[i*7+2] == "idle"):
                self.myConn.connect(list_services_info[i*7+1])

        eth_data = MyClass_json()
        eth_data.name_cmd = "eth_data"
        eth_data.control = "data_buff"
        eth_data.eth_number = cnt
        for i in range(cnt):
            eth_data.list_data.append(list_services_info[i * 8 + 3])    #name
            eth_data.list_data.append(list_services_info[i * 8 + 4])    #mac
            eth_data.list_data.append(list_services_info[i * 8 + 5])    #address
            eth_data.list_data.append(list_services_info[i * 8 + 6])    #netmask
            eth_data.list_data.append(list_services_info[i * 8 + 7])    #gateway

        eth_data_json = eth_data.__dict__
        eth_json = json.dumps(eth_data_json)
        # print eth_json
        send_message_to_html(eth_json, WebSocketHandler_myir)

    def read_eth_state_and_connect(self):
        cnt , list_services_info = self.myConn.get_services_info()
        for i in range(cnt):
            if (list_services_info[i*7+2] == "idle"):
                self.myConn.connect(list_services_info[i*7+1])

    def _read_eth(self):
        cnt, list_services_info = self.myConn.get_services_info()
        return cnt,list_services_info

class login(tornado.web.RequestHandler):
    def get(self):
        # lst = ["myirtech web demo"]
        # self.render("inde
        # x.html")
        # ip_str = get_ip_address("eth1")
        # self.render("index.html", info_ip=ip_str, info_port_eth=options.port, info_event="myir")
        pass
        self.render("login.html")
    def post(self,*args,**kwargs):
        username = self.get_argument('name')
        password = self.get_argument('pwd')

class login_in(tornado.web.RequestHandler):
    def get(self,*args,**kwargs):
        # self.write("login check")
        username = self.get_argument('usermail')
        password = self.get_argument('password')
    def post(self,*args,**kwargs):
        # self.write("welogin check")
        username = self.get_argument('Username')
        password = self.get_argument('Password')
        if username=="admin" and password=='admin':
            temp = str(GL.net_name)
            ip_str = get_ip_address(temp)
            self.render("index_en.html", info_ip=ip_str, info_port_eth=options.port, info_event="myir")
        else:
            self.render("login.html")
        # ip_str = get_ip_address("eth1")
        # self.render("index.html", info_ip=ip_str, info_port_eth=options.port, info_event="myir")

class language_change(tornado.web.RequestHandler):
    def get(self):
        self.render("login.html")
    def post(self,*args,**kwargs):
        language_read = self.get_argument('language')
        # print  language_read
        temp = str(GL.net_name)
        ip_str = get_ip_address(temp)
        if language_read=="zh":
            self.render("index_zh.html", info_ip=ip_str, info_port_eth=options.port, info_event="myir")
        else:
            self.render("index_en.html", info_ip=ip_str, info_port_eth=options.port, info_event="myir")

# ajax  method
# class AjaxHandler(tornado.web.RequestHandler):
#     def post(self):
#         global fd_tty
#         ret_data=self.get_argument("message")
#         ret_data_str = ret_data.encode("utf-8")
#         # recv_data = sent_data(fd_tty,ret_data_str,len(ret_data_str))
#         # self.write("data recv")
#         self.write(str(ret_data))
#
