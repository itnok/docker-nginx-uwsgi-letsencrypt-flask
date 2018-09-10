#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from flask import Flask, render_template, request, redirect
import sys, os, traceback
current_directory = os.path.dirname(os.path.realpath(__file__))
app = Flask(__name__)


@app.route("/") 
@app.route("/index")
def index():
    try:
        return render_template('index.html')
    except:
        return get_exception()

    
#Shows the public IP and etho0 IP of the machine (good for validation, e.g. load balancing)
@app.route("/ip_address") 
def ip_address():
    try:
        import requests
        public_ip = requests.get('http://ipv4.icanhazip.com').text.strip()
        request_ip = request.remote_addr
        return '''
Public IP: {public_ip} <br>
Request IP: {request_ip} <br>
'''.format(public_ip=public_ip, request_ip=request_ip)
    except:
        return get_exception()    
    

#Letsencrypt certbot
@app.route('/.well-known/acme-challenge/<token_value>')
def letsencrpyt(token_value):
    try:
        with open('{current_directory}/.well-known/acme-challenge/{token_value}'.format(current_directory=current_directory, token_value=token_value)) as f:
            answer = f.readline().strip()
        return str(answer)
    except:
        return get_exception()


#Displays the 500 error
@app.errorhandler(500)
def get_500_error(error):
    try:
        return "500 error - %s" % (error)
    except:
        return get_exception()


#Gets a client's IP address
def get_client_ip():
    'Gets client IP from xforward for or remote address if not proxied'
    if request.headers.getlist("X-Forwarded-For"):
        return request.headers.getlist("X-Forwarded-For")[0]
    else:
        return request.remote_addr


def get_exception():
    exc_type, exc_obj, exc_tb = sys.exc_info()
    fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
    return '''
Python Version: {version}
File: {file_name}
Error Type: {error_type}
Error Message: {error_message}
Traceback: 
{traceback}
         '''.format(
                    version =sys.version.split("(")[0],
                    file_name = fname,
                    error_type = exc_type.__name__,
                    error_message = exc_obj,
                    traceback = traceback.format_exc().replace(", in ",", in \n"),
                    )
