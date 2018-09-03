#!/bin/bash

#start supervisord to bring up webserver and sleep to be sure it's up
supervisord -n

#Run letsencrypt, if the parameters were given.  Output a log of the letsencrypt attempt
if [ -n "$1" ]; then
    python2 /home/flask/conf/setup-https.py $1 > /home/flask/letsencrypt-setup.txt
fi
