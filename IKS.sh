#!/bin/bash

# turn swap off
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# load the following kernel modules using modprobe command
sudo modprobe overlay
sudo modprobe br_netfilter

# For the permanent loading of these modules, create the file with following content
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF

# add the kernel parameters like IP forwarding. Create a file and load the parameters using sysctl command

sudo tee /etc/sysctl.d/kubernetes.conf <<EOT
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOT
# To load the above kernel parameters

sudo sysctl --system

# install docker

sudo apt update && sudo apt install docker.io -y
# We install docker for the calico cni plugin. The normal container we use here is containerd

# install containerd dependencies

sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

# add containerd repository

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/containerd.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# install containerd 

sudo apt update && sudo apt install containerd.io -y

# configure containerd so that it starts using SystemdCgroup

containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

# Restart containerd service so that above changes come into the affect

sudo systemctl restart containerd

# Add Kubernetes Package Repository

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# Download the public signing key for the Kubernetes package repository using curl

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# add the Kubernetes repository

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install Kubernetes Components (Kubeadm, kubelet & kubectl)

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# This is supposed to be installed on both the Master and slave nodes. Once you are done, you can initialize kubeadm on the master node generate a token and run the token on the slave node to. I'll advise you to run this script using ansible playbooks on the slave node