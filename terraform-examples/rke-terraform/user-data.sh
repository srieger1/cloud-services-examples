#!/bin/bash
#apt-get update
#apt-get -y upgrade
curl https://releases.rancher.com/install-docker/20.10.sh | sh
groupadd docker
usermod -aG docker ubuntu
