###############################################################################################
# Purpose:  Provide a nginx+uwsgi+Flask container on Ubuntu 16.04 via ports 80 and 443
#
# Forked from Matt Svensson <matt.svensson@gmail.com>
#    github - https://github.com/Ucnt/docker-flask-nginx-uwsgi
# Who forked it from Thatcher Peskens <thatcher@dotcloud.com>
#    github - https://github.com/atupal/dockerfile.flask-uwsgi-nginx
#
# Build:
# sudo docker build -t flaskapp .
#
# Run HTTP:
# sudo docker run \
#   -d -p 80:80 \
#   --restart=always \
#   -t --name flaskapp \
#   flaskapp
#
# Setup HTTPS Automatically with domain name (-d), cert name (-n) and email (-e).  DOMAIN ONLY:
# sudo docker run \
#   -d -p 80:80 -p 443:443 \
#   --restart=always \
#   -t --name flaskapp \
#   flaskapp "-d [domain_list_csv] -n [certname] -e [email_address]"
#
# Run for HTTPS but set up HTTPS certs later:
# sudo docker run \
#   -d -p 80:80 -p 443:443 \
#   --restart=always \
#   -t --name flaskapp \
#   flaskapp
#
#   Setup HTTPS after starting the container as HTTP:
#       - Run: /home/flask/conf/setup-https.py -d [domain_list_csv] -n [certname] -e [email_address]
###############################################################################################

FROM ubuntu:16.04

# Add all local code to the docker container and
COPY . /home/flask/

RUN \
# Change the HTTPS config scripts to executable
    chmod +x /home/flask/conf/setup-https.py && \
# Install basic requiremements
    apt-get update && \
    apt-get install -y \
        software-properties-common && \
# Add latest nginx repo and install base programs
    add-apt-repository -y \
        ppa:nginx/stable && \
# Update everything to the latest release
    apt-get update && \
    apt-get upgrade -y && \
# Install packages and dependencies
    apt-get install -y \
        software-properties-common \
        build-essential \
        vim \
        nginx \
        net-tools \
        python3-dev \
        python3-setuptools \
        python3-software-properties \
        supervisor \
        wget && \
# Install pip3
    easy_install3 pip && \
# Install python requirements
    pip3 install -r \
        /home/flask/conf/requirements.txt && \
# Config all the things, inititally for HTTP, not HTTPS
    rm -rf \
        /etc/nginx/sites-enabled/default && \
    ln -s \
        /home/flask/conf/nginx-http.conf \
        /etc/nginx/sites-enabled/ && \
    ln -s \
        /home/flask/conf/supervisor.conf \
        /etc/supervisor/conf.d/ && \
# Get Letsencrypt/Certbot for HTTPS
    wget -O \
        /home/flask/conf/certbot-auto \
        https://dl.eff.org/certbot-auto && \
    chmod a+x \
        /home/flask/conf/certbot-auto

# Expose both ports in case you want to start using HTTPS
EXPOSE 80 443

ENTRYPOINT ["/home/flask/start.sh"]
