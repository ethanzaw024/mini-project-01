#!/usr/bin/env bash

echo "[Running docker-install.sh]"

sudo apt-get update -y
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
# sudo apt-get install docker-ce=5:19.03.15~3-0~ubuntu-focal docker-ce-cli=5:19.03.15~3-0~ubuntu-focal containerd.io=1.5.11-1 -y
VERSION_STRING=5:25.0.1-1~ubuntu.22.04~jammy
sudo apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
#sudo apt-get install docker-ce docker-ce-cli containerd.io -y
docker --version
sudo usermod -aG docker vagrant
sudo chmod 666 /var/run/docker.sock
#newgrp docker
sleep 1
docker ps
