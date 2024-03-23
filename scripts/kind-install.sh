#!/usr/bin/env bash

echo "[Running kind-install.sh]"

sudo curl -L "https://kind.sigs.k8s.io/dl/v0.20.0/kind-$(uname)-amd64" -o /usr/local/bin/kind
sudo chmod +x /usr/local/bin/kind
kind version
