
## Objective:

- Setup Kind v1.29.1 cluster with Calico CNI in Air-Gapped environment.

## Git-repo Link:

https://github.com/ethanzaw024/mini-project-01

## Thoughts Process:

1: Deploy kind cluster v1.29.1 with Calico CNI to understand the complete setup, also to understand how Calico CNI works and to check the correctness of the configuration.

2: Explore Air-Gapped setup for kind and research requirement for Air-Gapped. Found that there are 2 ways to go about it.

a) Tar-ball method (Chose to go with this as this is simple and fast)

b) Private Registry method

3: Prepare configuration and manifests file such as kind, calico, metallb and download them locally as there will not be internet connection available.

4: Search docker images from Deployment/Statefulset/DaemonSet manifest files that was downloaded.

5: Pull those required docker images into your machine locally and prepare a tarball for future use.

6: Prepare and execute setup script.

7: Load docker images into kind clusters.

## System Setup Diagram:

![image](https://github.com/ethanzaw024/mini-project-01/assets/164651542/b8dab395-a3ed-48b2-a5e7-5918bdc891dc)


## Configuration Steps:

**`Pre-Step:`** On the air gapped machine with the internet access, Install these tools.

- `docker-install.sh`
    
    ```bash
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
    ```
    
- `kind-install.sh`
    
    ```bash
    #!/usr/bin/env bash
    
    echo "[Running kind-install.sh]"
    
    sudo curl -L "https://kind.sigs.k8s.io/dl/v0.20.0/kind-$(uname)-amd64" -o /usr/local/bin/kind
    sudo chmod +x /usr/local/bin/kind
    kind version
    ```
    
- `kubectl-install.sh`
    
    ```bash
    #!/usr/bin/env bash
    
    echo "[Running kubectl-install.sh]"
    sudo apt-get update -y
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sleep 0.5
    curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
    sleep 0.5
    echo "$(<kubectl.sha256) kubectl" | sha256sum --check
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    kubectl version --client
    sleep 0.5
    sudo rm -rf kubectl*
    ```
    
- `helm-install.sh`
    
    ```bash
    #!/usr/bin/env bash
    
    echo "[Running helm-install.sh]"
    
    curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
    sudo apt-get install apt-transport-https --yes
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt-get update
    sudo apt-get install helm
    helm version
    ```
    

**`Step 1:`** Prepare folder structure.

```jsx
# mkdir -p /home/vagrant/manifests/kind-cluster-offline; cd /home/vagrant/manifests/kind-cluster-offline/
# mkdir kind calico metallb
```

**`Step 2:`** Prepare Kind config file. Kind releases: https://github.com/kubernetes-sigs/kind/releases

```jsx
# cd /home/vagrant/manifests/kind-cluster-offline/kind/
# touch kindconfig-v12910.yaml
```

- `kindconfig-v12910.yaml`
    
    ```yaml
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    name: 129
    nodes:
    - role: control-plane
      image: kindest/node:v1.29.1@sha256:a0cc28af37cf39b019e2b448c54d1a3f789de32536cb5a5db61a49623e527144
    - role: worker
      image: kindest/node:v1.29.1@sha256:a0cc28af37cf39b019e2b448c54d1a3f789de32536cb5a5db61a49623e527144
    - role: worker
      image: kindest/node:v1.29.1@sha256:a0cc28af37cf39b019e2b448c54d1a3f789de32536cb5a5db61a49623e527144
    - role: worker
      image: kindest/node:v1.29.1@sha256:a0cc28af37cf39b019e2b448c54d1a3f789de32536cb5a5db61a49623e527144
    networking:
      podSubnet: 10.249.0.0/16
      serviceSubnet: 10.129.0.0/16
      disableDefaultCNI: true
    ```
    

**`Step 3:`** Download Calico manifest file into your local machine. Calico reference:  https://docs.tigera.io/calico/latest/getting-started/kubernetes/kind 

```jsx
# cd /home/vagrant/manifests/kind-cluster-offline/calico/
# wget https://raw.githubusercontent.com/projectcalico/calico/v3.27.2/manifests/calico.yaml
```

**`Step 4:`** Download Metallb manifest file into your local machine. Metallb reference: https://metallb.universe.tf/installation/  and  https://cloudgurupayments.medium.com/kubernetes-install-metallb-loadbalancer-27a01e323d00

```jsx
# cd /home/vagrant/manifests/kind-cluster-offline/metallb/
# wget https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
# wget https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
# touch metallb-cm.yaml
```

- `metallb-cm.yaml`
    
    ```yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      namespace: metallb-system
      name: config
    data:
      config: |
        address-pools:
        - name: default
          protocol: layer2
          addresses:
          - 172.18.255.150-172.18.255.169
    ```
    

**`Step 5:`** Search what are the docker images name mentioned inside all the manifest files downloaded in **Step 2/3/4**.

a) kind

```jsx
vagrant@mini-project-box:~/manifests/kind-cluster-offline/kind$ grep -i -w image *.yaml | sort -u
  image: kindest/node:v1.29.1@sha256:a0cc28af37cf39b019e2b448c54d1a3f789de32536cb5a5db61a49623e527144
```

b) calico

```jsx
vagrant@mini-project-box:~/manifests/kind-cluster-offline/calico$ grep -i -w image *.yaml | sort -u
          image: docker.io/calico/cni:v3.27.2
          image: docker.io/calico/kube-controllers:v3.27.2
          image: docker.io/calico/node:v3.27.2
```

c) metallb

```jsx
vagrant@mini-project-box:~/manifests/kind-cluster-offline/metallb$ grep -i -w image *.yaml | sort -u
        image: quay.io/metallb/controller:v0.12.1
        image: quay.io/metallb/speaker:v0.12.1
```

**`Step 6:`** Manually pull all the required docker images to local machine from dockerhub with the internet access and export them into tarball files for future use. Kind Air-Gapped setup: https://kind.sigs.k8s.io/docs/user/working-offline/

**Docker pull:** Download the docker images

```jsx
# docker pull kindest/node:v1.29.1@sha256:a0cc28af37cf39b019e2b448c54d1a3f789de32536cb5a5db61a49623e527144

# docker pull calico/cni:v3.27.2
# docker pull calico/kube-controllers:v3.27.2
# docker pull calico/node:v3.27.2

# docker pull quay.io/metallb/controller:v0.12.1
# docker pull quay.io/metallb/speaker:v0.12.1
```

**Docker image tag:** Tag the images with respective versions

```jsx
# docker image tag kindest/node:v1.29.1@sha256:a0cc28af37cf39b019e2b448c54d1a3f789de32536cb5a5db61a49623e527144 kindest/node:v1.29.1
```

**Docker save:** Export them into tarball for future use

```jsx
# docker save kindest/node:v1.29.1@sha256:a0cc28af37cf39b019e2b448c54d1a3f789de32536cb5a5db61a49623e527144 | gzip > ~/manifests/kind-cluster-offline/kind/kind.v1.29.1.tar.gz

# docker save calico/cni:v3.27.2 | gzip > ~/manifests/kind-cluster-offline/calico/calico-cni.v3.27.2.tar.gz
# docker save calico/kube-controllers:v3.27.2 | gzip > ~/manifests/kind-cluster-offline/calico/calico-controllers.v3.27.2.tar.gz
# docker save calico/node:v3.27.2 | gzip > ~/manifests/kind-cluster-offline/calico/calico-node.v3.27.2.tar.gz

# docker save quay.io/metallb/controller:v0.12.1 | gzip > ~/manifests/kind-cluster-offline/metallb/metallb-controller.v0.12.1.tar.gz
# docker save quay.io/metallb/speaker:v0.12.1 | gzip > ~/manifests/kind-cluster-offline/metallb/metallb-speaker.v0.12.1.tar.gz
```

**Docker load:** If you setup on new machine, you can load these tarball images. This step is not required for this setup.

```jsx
# docker load -i ~/manifests/kind-cluster-offline/kind/kind.v1.29.1.tar.gz

# docker load -i ~/manifests/kind-cluster-offline/calico/calico-cni.v3.27.2.tar.gz
# docker load -i ~/manifests/kind-cluster-offline/calico/calico-controllers.v3.27.2.tar.gz
# docker load -i ~/manifests/kind-cluster-offline/calico/calico-node.v3.27.2.tar.gz

# docker load -i ~/manifests/kind-cluster-offline/metallb/metallb-controller.v0.12.1.tar.gz
# docker load -i ~/manifests/kind-cluster-offline/metallb/metallb-speaker.v0.12.1.tar.gz
```

**`Step 7:`** Once all the manual work is done, move onto automation. I create the bash script with 2 options to install. 

During the testing, i have cut off the internet connection to simulate the air-gapped environment.

Choose (1): Setup Kind Cluster air-gapped.

Choose (2): Setup Kind Cluster Online. **#Not Required for this setup.**

```jsx
# touch ~/manifests/setup.sh
# ./setup.sh
```

- setup.sh
    
    ```bash
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
    ```
    

## Issue & troubleshooting:

Since I have everything I need, I started to deploy the kind cluster and hit into issueObserved that my node are not in ready state, so I straight away thought about my CNI pods that something was gone wrong. 

As expected, upon checking i saw that my calico CNI pods are stuck in '**ImagePullBackOff**' state. 

I was stuck here for awhile finding resolution and trying different ways, going to kind node to check with '**crictl**' whether or not my docker images are loaded.In the end I found on some **[article](https://iximiuz.com/en/posts/kubernetes-kind-load-docker-image/)** and someone is talking about '**kind load**' command. 

Tried the kind load command to load docker images into the kind cluster but it didn't' work. Reason is also because I am not too familiar with kind load command.

I continue to explore and found another source, this time i tried to find kind load command usage from **[kind official documentation](https://kind.sigs.k8s.io/docs/user/quick-start/#loading-an-image-into-your-cluster)** and managed to load the images into kind cluster. 

Once I have loaded them in, all the problem resolved and my air-gapped cluster was up and running successfully.

![image](https://github.com/ethanzaw024/mini-project-01/assets/164651542/7e4bd456-4e0e-4fa5-907e-a207cf000ecf)

**`Resolution:`**

```bash
kind load docker-image calico/cni:v3.27.2 --name $clusterName
kind load docker-image calico/node:v3.27.2 --name $clusterName
kind load docker-image calico/kube-controllers:v3.27.2 --name $clusterName
kind load docker-image quay.io/metallb/speaker:v0.12.1 --name $clusterName
kind load docker-image quay.io/metallb/controller:v0.12.1 --name $clusterName

# where $clusterName is the name of the kind cluster
```

## References:

| Website | URL |
| --- | --- |
| Kind Releases | https://github.com/kubernetes-sigs/kind/releases |
| Calico Official Documentation | https://docs.tigera.io/calico/latest/getting-started/kubernetes/kind |
| Metallb Official Documentation | https://metallb.universe.tf/installation/ |
| Metallb Setup | https://cloudgurupayments.medium.com/kubernetes-install-metallb-loadbalancer-27a01e323d00 |
| Kind AirGapped Setup | https://kind.sigs.k8s.io/docs/user/working-offline/ |
| ImagePullBackOff Article | https://iximiuz.com/en/posts/kubernetes-kind-load-docker-image/ |
| Kind Official Documentation | https://kind.sigs.k8s.io/docs/user/quick-start/#loading-an-image-into-your-cluster |
