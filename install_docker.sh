#!/usr/bin/env bash

# Docker install for a debian based system
sudo /usr/bin/env bash -c ' \
    apt-get update -y && \
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common && \
    curl -fsSL \
        https://download.docker.com/linux/ubuntu/gpg | \
        apt-key add - && \
    add-apt-repository \
        "deb [arch=$(dpkg-architecture | grep "DEB_TARGET_ARCH=" | cut -d= -f2)] \
        https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) \
        stable" && \
    apt-get update -y && \
    apt-get install -y \
        docker-ce && \
    docker --version \
';
