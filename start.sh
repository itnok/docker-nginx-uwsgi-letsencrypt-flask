#!/usr/bin/env bash

# Run letsencrypt, if the parameters were given. Output a log of the letsencrypt attempt
if [ -n "${1}" ]; then
    service nginx restart
    python /home/flask/conf/setup-https.py ${1} | tee /home/flask/letsencrypt-setup.txt
    service nginx stop
fi

# start supervisord to bring up webserver and sleep to be sure it's up
service supervisor start

# keep the container running...
tail -f /dev/null

