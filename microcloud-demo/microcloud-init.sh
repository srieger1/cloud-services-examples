#!/bin/bash
sudo microcloud init
lxc network set UPLINK dns.nameservers=8.8.8.8
