#!/bin/bash

sudo apt update
sudo apt install python3
sudo apt install software-properties-common -y
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install ansible -y
# Install this  script only on the kubernetes master