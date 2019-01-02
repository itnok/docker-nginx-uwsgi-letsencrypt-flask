###############################################################################################
# Purpose: Containerized Flask app served via Nginx+uWSGI on Ubuntu 16.04 over ports 80 and 443
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

# Set non interactive frontend for apt-get
ARG DEBIAN_FRONTEND=noninteractive

# Add all local code to the docker container
COPY . /home/flask/

RUN \
# Make executable the HTTPS config scripts
    chmod +x /home/flask/conf/setup-https.py && \
# Install basic requiremements
    apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common && \
# Add latest Nginx repo
    add-apt-repository -y \
        ppa:nginx/stable && \
# Update everything to the latest release
    apt-get update && \
    apt-get upgrade -y && \
# Install packages and dependencies
    apt-get install -y --no-install-recommends \
        software-properties-common \
        build-essential \
        vim \
        nginx \
        net-tools \
        python3-dev \
        python3-software-properties \
        supervisor \
        dirmngr \
        gnupg2 \
        wget && \
# Install pip3
    wget -O \
        /tmp/get-pip.py \
        https://bootstrap.pypa.io/get-pip.py && \
    python3 /tmp/get-pip.py && \
    rm -rf /tmp/get-pip.py && \
# Install python requirements
    pip3 install -r \
        /home/flask/conf/requirements.txt && \
# Config all the things, inititally for HTTP, not HTTPS
    rm -rf \
        /etc/nginx/nginx.conf && \
    cp \
        /home/flask/conf/nginx.conf \
        /etc/nginx/nginx.conf && \
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
        /home/flask/conf/certbot-auto && \
# Check Certbot is authentic
    wget -O \
        /tmp/certbot-auto.asc \
        https://dl.eff.org/certbot-auto.asc && \
    gpg2 \
        --keyserver pool.sks-keyservers.net \
        --recv-key A2CFB51FA275A7286234E7B24D17C995CD9775F2 && \
    gpg2 \
        --trusted-key 4D17C995CD9775F2 \
        --verify /tmp/certbot-auto.asc \
        /home/flask/conf/certbot-auto && \
    rm -rf /tmp/certbot-auto.asc && \
# Create acme-challenge directory to decouple Letsencrpyt/Certbot from uWSGI/Flask
    mkdir -p /var/www/html/.well-known/acme-challenge && \
# Create Diffie-Hellman parameter for DHE ciphersuites (very lengthy operation!) 
    openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096 && \
# Clean apt cache to save disk space and make image leaner
    apt-get clean

# Expose both ports in case you want to start using HTTPS
EXPOSE 80 443

ENTRYPOINT ["/home/flask/start.sh"]
