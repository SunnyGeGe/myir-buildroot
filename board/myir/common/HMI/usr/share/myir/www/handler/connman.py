#!/usr/bin/env python
#coding:utf-8

from __future__ import unicode_literals

import functools
import logging

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
import pyconnman

DBUS_DOMAIN = "net.connman"

def convert_dbus(obj):
    if (type(obj) is dbus.Byte):
        return int(obj)
    return obj

def make_string(str):
    return dbus.String(str, variant_level=1)

APP_NAME  = 'connman'
SHORT_DEV = True
SHOW_ADDR = True


PROTO_LST = ['IPv4', 'IPv6']
STATE_IGN = ['ready', 'idle']
STATE_MAP = {'disconnect': 'disconnected',
             'association': 'associating ...',
             'configuration': 'configuring ...'}


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

        for prop in self._exposed_properties:
            def mysetter(name, this, value):
                this.dbus.SetProperty(name, value)
            def mygetter(name, this):
                return this.properties.get(name)
            myprop = property(fget=functools.partial(mygetter, prop), fset=functools.partial(mysetter, prop))
            setattr(self.__class__, prop.lower(), myprop)

    def get_services_info(self):
        list_services_info = []
        servers_cnt=0
        for path, properties in self.manager.GetServices():
            serviceId = path[path.rfind("/") + 1:]
            servers_cnt = servers_cnt + 1    # 个数

            list_services_info.append(path)
            list_services_info.append(serviceId)
            list_services_info.append(properties["State"])

            list_services_info.append(properties.get("Ethernet").get('Interface')) ## net name
            list_services_info.append(properties.get("Ethernet").get('Address'))   ##  MAC
            list_services_info.append(properties.get("IPv4").get('Address'))       ## ipv4 ip
            list_services_info.append(properties.get("IPv4").get('Netmask'))       ## ipv4  子掩码
            list_services_info.append(properties.get("IPv4").get('Gateway'))       ## ipv4  网关

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

    def set_ipaddress(self, tech_path,address, netmask, gateway):

        # tech = dbus.Interface(self.bus.get_object('net.connman', '/'), 'net.connman.Service')
        # properties = tech.GetProperties()

        # shorten device names
        # srv_name = tech_path[tech_path.rfind("/") + 1:]
        # if SHORT_DEV:
        #     srv_name = srv_name[0:srv_name.find("_")]

        srv_obj = dbus.Interface(self.__bus.get_object('net.connman', '/'), 'net.connman.Service')
        # srv_prop = None
        # try:

        srv_prop = srv_obj.GetProperties()

        #     if 'Name' in srv_prop:
        #         srv_name += "/" + srv_prop['Name']
        #     if SHOW_ADDR and value == 'online':
        #         addrs = []
        #         for proto in PROTO_LST:
        #             if proto in srv_prop and 'Address' in srv_prop[proto]:
        #                 addrs.append(str(srv_prop[proto]['Address']))
        #         if addrs:
        #             state += " [" + ", ".join(addrs) + "]"
        # except dbus.DBusException:
        #     pass

        # ip4config = "IPv4.Configuration"
        #
        # # tech = pyconnman.ConnTechnology(tech_path)
        #
        # tech = pyconnman.ConnService(tech_path)
        # # service.set_property(name, value)
        #
        # ip_address = {'Method': 'manual', 'Address': address, 'Netmask': netmask}
        # if gateway:
        #     ip_address['Gateway'] = gateway
        #     self.dbus.SetProperty(ip4config, ip_address)

            # tech.set_property(make_string(ip4config), make_string(ip_address))
        # if nameservers:
        #     self.dbus.SetProperty(self.dnsconfig, nameservers)
        # tech.set_property(name, value)
