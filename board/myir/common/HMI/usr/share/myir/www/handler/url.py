#!/usr/bin/env python
#coding:utf-8

import tornado.httpserver
import tornado.ioloop
import tornado.options
import tornado.web
# '''
# import tornado.httpclient
# import tornado.gen
# '''
# '''
# from tornado.concurrent import run_on_executor
# from concurrent.futures import ThreadPoolExecutor
# '''

import time
import sys
reload(sys)
sys.setdefaultencoding('utf-8')

from handler.index import login
from handler.index import login_in
# from handler.index import gui_switch
# from handler.index import home_led
# from handler.index import home_uart
# from handler.index import AjaxHandler
# from handler.index import ChatHandler
# from handler.index import WebSocketHandler_uart
# from handler.index import WebSocketHandler_led
# from handler.index import WebSocketHandler_can
# from handler.index import WebSocketHandler_eth

from handler.index import WebSocketHandler_myir
from handler.index import language_change

'''
# from server import SleepHandler
class SleepHandler(tornado.web.RequestHandler):
    executor = ThreadPoolExecutor(2)

    def get(self):
        tornado.ioloop.IOLoop.instance().add_callback(self.sleep)       # 这样将在下一轮事件循环执行self.sleep
        self.write("when i sleep")

    @run_on_executor
    def sleep(self):
        time.sleep(5)
        print("yes")
        return 5
'''

url=[
   # (r"/sleep",SleepHandler),
    (r'/login', login),
    (r'/login_in', login_in),
    (r'/myir', WebSocketHandler_myir),
    (r'/myir_z', language_change),

]
