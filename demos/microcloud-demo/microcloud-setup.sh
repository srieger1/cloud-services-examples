#!/bin/bash
#sudo snap refresh lxd --channel=5.21/stable --cohort="+"
sudo snap install lxd --channel=5.21/stable --cohort="+"
sudo snap install microceph --channel=quincy/stable --cohort="+"
sudo snap install microovn --channel=22.03/stable --cohort="+"
sudo snap install microcloud --channel=latest/stable --cohort="+"

sudo snap refresh --hold lxd microceph microovn microcloud

#sudo microcloud init
