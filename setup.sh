#!/usr/bin/env bash

export clusterName=airgapped-cluster

echo "[Kind Cluster Setup]"
echo

while true; do
    echo "Choose (1): Setup Kind Cluster air-gapped."
    echo "Choose (2): Setup Kind Cluster Online."
    read -p "Please select an option: " Number
    echo
    echo  "You have selected option $Number."
    echo
    case $Number in
        1)
            echo "[Setting up Kind Cluster air-gapped]"
            kind create cluster --image kindest/node:v1.29.1 --config ~/manifests/kind-cluster-offline/kind/kindconfig-v12910.yaml --name $clusterName
            sleep 1
            echo
            echo "[Setting up Calico CNI]"
            #kubectl apply -f ~/manifests/kind-cluster-offline/calico/tigera-operator.yaml
            #kubectl apply -f ~/manifests/kind-cluster-offline/calico/custom-resources.yaml
            kubectl apply -f ~/manifests/kind-cluster-offline/calico/calico.yaml
            sleep 1
            echo
            echo "[Setting up Metallb Offline]"
            kubectl apply -f ~/manifests/kind-cluster-offline/metallb/namespace.yaml
            kubectl apply -f ~/manifests/kind-cluster-offline/metallb/metallb.yaml
            sleep 0.5
            kubectl create -f ~/manifests/kind-cluster-offline/metallb/metallb-cm.yaml
            echo
            echo "[Load Docker Images]"
            echo
            echo "Loading Calico CNI images................"
            kind load docker-image calico/cni:v3.27.2 --name $clusterName
            echo "#########################################################"
            sleep 1
            kind load docker-image calico/node:v3.27.2 --name $clusterName
            echo "#########################################################"
            sleep 1
            kind load docker-image calico/kube-controllers:v3.27.2 --name $clusterName
            echo "#########################################################"
            sleep 1
            echo
            echo "Loading Metallb image................."
            kind load docker-image quay.io/metallb/speaker:v0.12.1 --name $clusterName
            sleep 1
            kind load docker-image quay.io/metallb/controller:v0.12.1 --name $clusterName
            echo "#########################################################"
            sleep 1
            echo
            break
            ;;
        2)
            echo "[Setting up Kind Cluster Online]"
            kind create cluster --config ~/manifests/kind-cluster/kindconfig-v12910.yaml --name $clusterName
            sleep 1
            echo
            echo "[Setting up Calico CNI]"
            kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/tigera-operator.yaml
            kubectl apply -f ~/manifests/kind-cluster-offline/calico/custom-resources.yaml
            sleep 1
            echo "[Setting up Metallb Online]"
            kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
            kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
            sleep 0.5
            kubectl create -f ~/manifests/kind-cluster/metallb-cm.yaml
            echo
            break
            ;;
        *)
            echo "Invalid option! Please enter a valud option (1 or 2)."
            echo "#########################################################"
            echo
            ;;
    esac
done