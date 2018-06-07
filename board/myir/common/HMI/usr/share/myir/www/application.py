#!/usr/bin/env python
#coding:utf-8

import os
import tornado.web
from handler.url import url

setting = dict(
    template_path=os.path.join(os.path.dirname(__file__),"template"),
    static_path=os.path.join(os.path.dirname(__file__),"statics"),
    static_url_prefix=os.path.join(os.path.dirname(__file__),"/statics/"),
    # "static_path":os.path.join(os.path.dirname(__file__), "static"),
    # 'static_url_prefix':'/static/',
    )

# setting = {
#
#     'template_path': 'template',
#     'static_path': 'statics',
#     'static_url_prefix': '/statics/',
# }

application = tornado.web.Application(
    handlers=url,
    **setting
    )
