#!/usr/bin/env python
#coding:utf-8

from __future__ import unicode_literals

import functools
import logging
import ctypes
from ctypes import *
import readline  # noqa
import os
import sys
import dbus
import dbus.mainloop.glib
#import gobject
from gi.repository import GLib
#from gi.repository import gobject
import signal
# from collections import namedtuple
import time
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
import traceback
# import pylibmc
import pyconnman

DBUS_DOMAIN = "net.connman"

def convert_dbus(obj):
    if (type(obj) is dbus.Byte):
        return int(obj)
    return obj

def make_string(str):
    return dbus.String(str, variant_level=1)

class ConnmanClient:
    path = "/net/connman/service/"
    _exposed_properties = tuple()
    # Setting up bus
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    def __init__(self, autoconnect_timeout):
        self.__bus = dbus.SystemBus()
        # self.bus = dbus.SessionBus()
        self.manager = dbus.Interface(self.__bus.get_object("net.connman", "/"),
                "net.connman.Manager")
        # self.technology = dbus.Interface(self.bus.get_object("net.connman",
        #         "/"), "net.connman.Service")
        self.dbus = dbus.Interface(self.__bus.get_object(DBUS_DOMAIN, '/'),
                        'net.connman.Service')
        self.manager_py = pyconnman.ConnManager()

        try:
            # manager = pyconnman.ConnManager()
            self.manager_py.add_signal_receiver(self.dump_signal,
                                        pyconnman.ConnManager.SIGNAL_TECHNOLOGY_ADDED,
                                        None)
            self.manager_py.add_signal_receiver(self.dump_signal,
                                        pyconnman.ConnManager.SIGNAL_TECHNOLOGY_REMOVED,  # noqa
                                        None)
            self.manager_py.add_signal_receiver(self.dump_signal,
                                        pyconnman.ConnManager.SIGNAL_SERVICES_CHANGED,
                                        None)
            self.manager_py.add_signal_receiver(self.dump_signal,
                                        pyconnman.ConnManager.SIGNAL_PROPERTY_CHANGED,
                                        None)
        except dbus.exceptions.DBusException:
            print 'Unable to complete:', sys.exc_info()

    def dump_signal(self,signal, *args):
        # print '\n========================================================='
        # print '>>>>>', signal, '<<<<<'
        # print args
        # print '========================================================='
        from handler.index import GL
        GL.net_change=1

    def get_services_info(self):
        list_services_info = []
        servers_cnt=0
        tempv=" "

        # services = self.manager_py.get_services()
        for path, properties in self.manager_py.get_services():

            serviceId = path[path.rfind("/") + 1:]
            servers_cnt = servers_cnt + 1    # 个数

            list_services_info.append(path)
            list_services_info.append(serviceId)
            list_services_info.append(properties["State"])

            list_services_info.append(properties.get("Ethernet").get('Interface')) ## net name
            list_services_info.append(properties.get("Ethernet").get('Address'))   ##  MAC
            list_services_info.append(properties.get("IPv4").get('Address'))       ## ipv4 ip
            list_services_info.append(properties.get("IPv4").get('Netmask'))       ## ipv4  子掩码
            tempv = properties.get("IPv4").get('Gateway')
            if tempv==None:
                tempv = properties.get("IPv4.Configuration").get('Gateway')
            list_services_info.append(tempv)       ## ipv4  网关


        # for path, properties in self.manager.GetServices():
        #     serviceId = path[path.rfind("/") + 1:]
        #     servers_cnt = servers_cnt + 1    # 个数
        #     list_services_info.append(path)
        #     list_services_info.append(serviceId)
        #     list_services_info.append(properties["State"])
        #     list_services_info.append(properties.get("Ethernet").get('Interface')) ## net name
        #     list_services_info.append(properties.get("Ethernet").get('Address'))   ##  MAC
        #     list_services_info.append(properties.get("IPv4.Configuration").get('Address'))       ## ipv4 ip
        #     list_services_info.append(properties.get("IPv4.Configuration").get('Netmask'))       ## ipv4  子掩码
        #     list_services_info.append(properties.get("IPv4.Configuration").get('Gateway'))       ## ipv4  网关

        return servers_cnt,list_services_info

    # def get_state(self,ServiceId):
    #     for path,properties in self.manager.GetServices():
    #         if path == self.path + ServiceId:
    #                 return properties["State"]

    # def get_services_id(self):
    #     list_servicesid = []
    #     cnt=0
    #     for path, properties in self.manager.GetServices():   ## 没有网络时执行此处会卡死在此处
    #         serviceId = path[path.rfind("/") + 1:]
    #         cnt = cnt + 1
    #         list_servicesid.append(serviceId)
    #     return list_servicesid,cnt

    # def list_services_cnt(self):
    #     count=0
    #     try:
    #         services = self.manager_py.get_services()
    #         for i in services:
    #             (path, params) = i
    #             # print path, '[' + params['Name'] + ']'
    #             count =count+1
    #     except dbus.exceptions.DBusException:
    #         print 'Unable to complete:', sys.exc_info()
    #     return count

    def get_ipv4(self):
        count = 0
        list_servicesid_ipv4 = []
        for path, properties in self.manager.GetServices():
            count = count + 1
            list_servicesid_ipv4.append(properties.get("Ethernet").get('Interface')) ## net name
            list_servicesid_ipv4.append(properties.get("Ethernet").get('Address')) ##  MAC

            list_servicesid_ipv4.append(properties.get("IPv4").get('Address'))     ## ipv4 ip
            list_servicesid_ipv4.append(properties.get("IPv4").get('Netmask'))     ## ipv4  子掩码
            list_servicesid_ipv4.append(properties.get("IPv4").get('Gateway'))     ## ipv4 网关

        return list_servicesid_ipv4,count

    def connect(self,services_id):
        service_path=self.path+services_id
        try:
            service = pyconnman.ConnService(service_path)
            service.connect()
        except dbus.exceptions.DBusException:
            print 'Unable to complete:', sys.exc_info()

    def dissconnect(self,services_id):
        service_path = self.path + services_id
        try:
            service = pyconnman.ConnService(service_path)
            service.remove()
        except dbus.exceptions.DBusException:
            print 'Unable to complete:', sys.exc_info()

    def set_ipv4(self,Netmask,Gateway,Method,Address,net_name):
        cnt, list_services_info=self.get_services_info()

        for i in range(cnt):
            if(list_services_info[i*8+3]==net_name):
                service_py = pyconnman.ConnService(list_services_info[i*8+0])
                name="IPv4.Configuration"
                value22 = {dbus.String(u'Netmask'): dbus.String(Netmask,variant_level=1),dbus.String(u'Gateway'): dbus.String(Gateway,variant_level=1),dbus.String(u'Method'): dbus.String(Method,variant_level=1),dbus.String(u'Address'): dbus.String(Address,variant_level=1)}
                service_py.set_property(name, value22)
    def set_ipv4_dhcp(self,Method,net_name):
        cnt, list_services_info=self.get_services_info()
        for i in range(cnt):
            if(list_services_info[i*8+3]==net_name):
                service_py = pyconnman.ConnService(list_services_info[i*8+0])
                name="IPv4.Configuration"
                value22 = {dbus.String(u'Method'):dbus.String(Method,variant_level=1)}
                service_py.set_property(name, value22)