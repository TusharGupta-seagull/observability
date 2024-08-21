#! /usr/bin/env bash

# This script is common script for all nodes(Control Plane and Worker Nodes)
set -xueo pipefail

KUBERNETES_VERSION=v1.30
CRIO_VERSION=v1.30

sudo apt-get update -y

# Disable swap
sudo swapoff -a

# Create cronjob to disable swap on reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true

# Load kernal modules at boot
sudo tee /etc/modules-load.d/k8s.conf > /dev/null <<EOF
overlay
br_netfilter
EOF

# Load kernal modules
sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
sudo tee /etc/sysctl.d/k8s.conf > /dev/null <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

sudo apt-get install apt-transport-https software-properties-common curl ca-certificates -y

# Add CRI-O repository
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/cri-o.list

# Add Kubernetes repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y

# Install CRI-O runtime and kubernetes
sudo apt-get install cri-o kubelet kubeadm kubectl -y

sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl start crio.service

sudo systemctl enable kubelet --now
sudo systemctl start kubelet
