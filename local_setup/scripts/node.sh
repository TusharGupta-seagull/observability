#! /usr/bin/env bash

# setup for worker nodes
set -xueo pipefail

config_path="/vagrant/configs"

/bin/bash $config_path/join.sh -v


# Adding label to the worker node
sudo -i -u vagrant bash << EOF
mkdir -p /home/vagrant/.kube
cp $config_path/config /home/vagrant/.kube/config 
chown 1000:1000 /home/vagrant/.kube/config 
kubectl label node $(hostname -s) node.role.kubernetes.io/worker=worker
EOF

# For root user
# mkdir -p $HOME/.kube
# cp $config_path/config $HOME/.kube/config 
# chown $(id -u):$(id -g) $HOME/.kube/config


