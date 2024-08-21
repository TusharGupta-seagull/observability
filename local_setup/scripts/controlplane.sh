#! /usr/bin/env bash

# Setup for controlplane nodes

set -xueo pipefail

CALICO_VERSION=3.26.0

POD_CIDR="192.168.0.0/16"
SVC_CIDR="10.96.0.0/12"
CONTROL_IP="10.0.0.10"

sudo kubeadm config images pull

sudo kubeadm init \
	--apiserver-advertise-address=$CONTROL_IP \
	--apiserver-cert-extra-sans=$CONTROL_IP \
	--pod-network-cidr=$POD_CIDR \
	--service-cidr=$SVC_CIDR \
	--node-name "$(hostname -s)" \
	--ignore-preflight-errors Swap

# FOR CURRENT USER (root)
mkdir -p $HOME/.kube 
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

config_path="/vagrant/configs"

if [ -d $config_path ]; then 
	rm -rf $config_path/*
else
	mkdir -p $config_path
fi

# Copy "kubeconfig file" and "token join commmand" to the synced_folder
sudo cp /etc/kubernetes/admin.conf $config_path/config 
touch $config_path/join.sh 
chmod +x $config_path/join.sh 

kubeadm token create --print-join-command > $config_path/join.sh 

# Install Calico plugin
curl https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/calico.yaml -O

kubectl apply -f calico.yaml

# For vagrant user
sudo -i -u vagrant bash << EOF
mkdir -p /home/vagrant/.kube 
sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown 1000:1000 /home/vagrant/.kube/config
EOF