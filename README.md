# cocloud-k8s-dev-cluster-stitch
 COCloud K8s Development Cluster Stitch
 on Ubuntu 24.04.1 LTS

Cantrell Cloud Enterprise Services
designed by:
	Ron Cantrell
	ron@cantrelloffice.cloud

---

## Table of Contents

> TOC in future release
>
---

## Introduction

After carefully following the below instructions, only a single master cluster will be deployed.
You then need to join any other node using the generated key and label.

Following the instructions given, you should be able to configure and initialize a default
Kubernetes cluster with NSX networking overlays.

### This is the desired end state for the Enterprise

Clusters will be packageable for multiple deployments on any storage.

```
+===============================================================================================+
|                                                                                               |
|  +-----------------------------------------------------------------------------------------+  |
|  | INGRESS (kube-vip)                                                                      |  |
|  |                                                                                         |  |
|  |     +----------------+             +----------------+            +-----------------+    |  |
|  |     | foo.domain.tld |             | www.domain.ltd |            | app1.domain.ltd |    |  |
|  |     +----------------+             +----------------+            +-----------------+    |  |
|  |             |                              |                              |             |  |
|  +-----------------------------------------------------------------------------------------+  |
|                |                              |                              |                |
|                |                              |                              |                |
|  +---------------------------+  +---------------------------+  +---------------------------+  |
|  |             |             |  |             |             |  |             |             |  |
|  |  +---------------------+  |  |  +---------------------+  |  |  +---------------------+  |  |
|  |  | SERVICE (ClusterIP) +  |  |  | SERVICE (ClusterIP) |  |  |  | SERVICE (ClusterIP) |  |  |
|  |  +---------------------+  |  |  +---------------------+  |  |  +---------------------+  |  |
|  |     |       |       |     |  |     |       |       |     |  |     |       |       |     |  |
|  |     |       |       |     |  |     |       |       |     |  |     |       |       |     |  |
|  |     \       |       /     |  |     \       |       /     |  |     \       |       /     |  |
|  |  +-----+ +-----+ +-----+  |  |  +-----+ +-----+ +-----+  |  |  +-----+ +-----+ +-----+  |  |
|  |  | POD | | POD | | POD |  |  |  | POD | | POD | | POD |  |  |  | POD | | POD | | POD |  |  |
|  |  +-----+ +-----+ +-----+  |  |  +-----+ +-----+ +-----+  |  |  +-----+ +-----+ +-----+  |  |
|  |                           |  |                           |  |                           |  |
|  | WORKER NODE               |  | WORKER NODE               |  | WORKER NODE               |  |
|  +---------------------------+  +---------------------------+  +---------------------------+  |
|                                                                                               |
| KUBERNETES CLUSTER                                                                            |
+===============================================================================================+
```

### Reserved Cluster IP Address Blocks

- example of ip networks and subnets

```
KUBEURNETES_EXTERNAL_ROUTED_VLANS
255.255.255.0	subnetname	10.0.68.0/24		10.0.68.1 - 10.0.68.254			10.0.68.255
255.255.255.224	namespace	10.0.68.0/27		10.0.68.1 - 10.0.68.30			10.0.68.31
255.255.255.224	namespace	10.0.68.32/27		10.068.33 - 10.0.68.62			10.0.68.63
255.255.255.224	namespace	10.0.68.64/27		10.0.68.65 - 10.0.68.94			10.0.68.95
255.255.255.224	namespace	10.0.68.96/27		10.0.68.97 - 10.0.68.126		10.0.68.127
255.255.255.224	namespace	10.0.68.128/27		10.0.68.129 - 10.0.68.158		10.0.68.159
255.255.255.224	namespace	10.0.68.160/27		10.0.68.161 - 10.0.68.190		10.0.68.191
255.255.255.224	namespace	10.0.68.192/27		10.0.68.193 - 10.0.68.222		10.0.68.223
255.255.255.224	namespace	10.0.68.224/27		10.0.68.225 - 10.0.68.254		10.0.68.255

KUBEURNETES_INTERNAL_ROUTED_VLANS	
255.255.255.0	subnetname	10.0.69.0/24		10.0.69.1 - 10.0.69.254			10.0.69.255
255.255.255.224	namespace	10.0.69.0/27		10.0.69.1 - 10.0.69.30			10.0.69.31
255.255.255.224	namespace	10.0.69.32/27		10.0.69.33 - 10.0.69.62			10.0.69.63
255.255.255.224	namespace	10.0.69.64/27		10.0.69.65 - 10.0.69.94			10.0.69.95
255.255.255.224	namespace	10.0.69.96/27		10.0.69.97 - 10.0.69.126		10.0.69.127
255.255.255.224	namespace	10.0.69.128/27		10.0.69.129 - 10.0.69.158		10.0.69.159
255.255.255.224	namespace	10.0.69.160/27		10.0.69.161 - 10.0.69.190		10.0.69.191
255.255.255.224	namespace	10.0.69.192/27		10.0.69.193 - 10.0.69.222		10.0.69.223
255.255.255.224	namespace	10.0.69.224/27		10.0.69.225 - 10.0.69.254		10.0.69.255

KUBEURNETES_EXTERNAL_PRODUCTION_VLANS
255.255.255.0	subnetname	172.16.68.0/24		172.16.68.1 - 172.16.68.254		172.16.68.255
255.255.255.224	namespace	172.16.68.0/27		172.16.68.1 - 172.16.68.30		172.16.68.31
255.255.255.224	namespace	172.16.68.32/27		10.068.33 - 172.16.68.62		172.16.68.63
255.255.255.224	namespace	172.16.68.64/27		172.16.68.65 - 172.16.68.94		172.16.68.95
255.255.255.224	namespace	172.16.68.96/27		172.16.68.97 - 172.16.68.126	172.16.68.127
255.255.255.224	namespace	172.16.68.128/27	172.16.68.129 - 172.16.68.158	172.16.68.159
255.255.255.224	namespace	172.16.68.160/27	172.16.68.161 - 172.16.68.190	172.16.68.191
255.255.255.224	namespace	172.16.68.192/27	172.16.68.193 - 172.16.68.222	172.16.68.223
255.255.255.224	namespace	172.16.68.224/27	172.16.68.225 - 172.16.68.254	172.16.68.255

KUBEURNETES_INTERNAL_PRODUCTION_VLANS
255.255.255.0	subnetname	172.16.69.0/24		172.16.69.1 - 172.16.69.254		172.16.69.255
255.255.255.224	namespace	172.16.69.0/27		172.16.69.1 - 172.16.69.30		172.16.69.31
255.255.255.224	namespace	172.16.69.32/27		172.16.69.33 - 172.16.69.62		172.16.69.63
255.255.255.224	namespace	172.16.69.64/27		172.16.69.65 - 172.16.69.94		172.16.69.95
255.255.255.224	namespace	172.16.69.96/27		172.16.69.97 - 172.16.69.126	172.16.69.127
255.255.255.224	namespace	172.16.69.128/27	172.16.69.129 - 172.16.69.158	172.16.69.159
255.255.255.224	namespace	172.16.69.160/27	172.16.69.161 - 172.16.69.190	172.16.69.191
255.255.255.224	namespace	172.16.69.192/27	172.16.69.193 - 172.16.69.222	172.16.69.223
255.255.255.224	namespace	172.16.69.224/27	172.16.69.225 - 172.16.69.254	172.16.69.255`
```

- COCloud networks and subnets

```
255.255.254.0	COPINE K8 Cluster - serviceSubnets	10.0.212.0/23		10.0.212.1 - 10.0.213.254		10.0.213.255
255.255.255.0		cluster serviceSubnets				10.0.212.0/24		10.0.212.1 - 10.0.212.254		10.0.212.255
255.255.255.192			cluster 01 dev						10.0.212.0/26		10.0.212.1 - 10.0.212.62		10.0.212.63
255.255.255.192			cluster 02							10.0.212.64/26		10.0.212.65 - 10.0.212.126		10.0.212.127
255.255.255.192			cluster 03							10.0.212.128/26		10.0.212.129 - 10.0.212.190		10.0.212.191
255.255.255.192			cluster 04							10.0.212.192/26		10.0.212.193 - 10.0.212.254		10.0.212.255
255.255.255.0		cluster serviceSubnet				10.0.213.0/24		10.0.213.1 - 10.0.213.254		10.0.213.255
255.255.255.192			cluster 05							10.0.213.0/26		10.0.213.1 - 10.0.213.62		10.0.213.63
255.255.255.192			cluster 06							10.0.213.64/26		10.0.213.65 - 10.0.213.126		10.0.213.127
255.255.255.192			cluster 07							10.0.213.128/26		10.0.213.129 - 10.0.213.190		10.0.213.191
255.255.255.192			cluster 08							10.0.213.192/26		10.0.213.193 - 10.0.213.254		10.0.213.255
255.255.254.0	COPINE K8 Cluster01 - podSubnets	172.16.212.0/23		172.16.212.1 - 172.16.213.254	172.16.213.255
255.255.255.0		cluster podSubnets					172.16.212.0/24		172.16.212.1 - 172.16.212.254	172.16.212.255
255.255.255.192			cluster 01 dev						172.16.212.0/26		172.16.212.1 - 172.16.212.62	172.16.212.63
255.255.255.248			namespace 01 - pihole				172.16.212.0/29		172.16.212.1 - 172.16.212.6		172.16.212.7
							copine-pihole01		172.16.212.1	
							copine-pihole02		172.16.212.2	
255.255.255.192			cluster 02							172.16.212.64/26	172.16.212.65 - 172.16.212.126	172.16.212.127
255.255.255.192			cluster 03							172.16.212.128/26	172.16.212.129 - 172.16.212.190	172.16.212.191
255.255.255.192			cluster 04							172.16.212.192/26	172.16.212.193 - 172.16.212.254	172.16.212.255
255.255.255.0		podSubnet							172.16.213.0/24		172.16.213.1 - 172.16.213.254	172.16.213.255
255.255.255.192			cluster 05							172.16.213.0/26		172.16.213.1 - 172.16.213.62	172.16.213.63
255.255.255.192			cluster 06							172.16.213.64/26	172.16.213.65 - 172.16.213.126	172.16.213.127
255.255.255.192			cluster 07							172.16.213.128/26	172.16.213.129 - 172.16.213.190	172.16.213.191
255.255.255.192			cluster 08							172.16.213.192/26	172.16.213.193 - 172.16.213.254	172.16.213.255
```

---

## Deploy Kubernetes

### References and Notes

https://www.virtualizationhowto.com/2023/12/how-to-install-kubernetes-in-ubuntu-22-04-with-kubeadm/

https://controlplane.com/community-blog/post/the-complete-kubectl-cheat-sheet

https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/onpremises

https://docs.tigera.io/calico/latest/operations/calicoctl/install#install-calicoctl-as-a-kubectl-plugin-on-a-single-host

https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/

https://tamerlan.dev/load-balancing-in-kubernetes-a-step-by-step-guide/

Scheduling

https://github.com/kubernetes/community/blob/master/contributors/devel/sig-scheduling/scheduling_code_hierarchy_overview.md

https://kubernetes.io/blog/2017/03/advanced-scheduling-in-kubernetes/

https://jvns.ca/blog/2017/07/27/how-does-the-kubernetes-scheduler-work/

https://stackoverflow.com/questions/28857993/how-does-kubernetes-scheduler-work

Monitoring

`kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`

```kubectl top node
kubectl top pod
```

Logging

`kubectl logs -f pod-name-here container-name-here`

Rollouts

```
kubectl rollout status deployment/my-deployment
kubectl rollout history deployment/my-deployment

kubectl rollout undo deployment/my-deployment
```

Configuring Applications

```
docker run ubuntu
docker build -t ubuntu-sleeper .
docker run ubuntu-sleeper

```

ConfigMaps

```
kubectl create configmap \
	app-config --from-literal=APP_COLOR=blue
```

```
apiVersion: v1
kind: ConfigMap
metadata:
	name: app-config
data:
	APP_COLOR: blue
	APP_MODE: prod
```

`kubectl get configmaps`

Secrets

```
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
data:
  DB_Host: mysql
  DB_User: root
  DB_Password: paswrd
```

```
echo -n 'mysql'  | base64
echo -n 'root'   | base64
echo -n 'paswrd' | base64
```

```
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
data:
  DB_Host: bXlzcWw=
  DB_User: cm9vdA==
  DB_Password: cGFzd3Jk
```

Add to pod definition files


```
envFrom:
- secretRef:
  name: app-secret
```

### Repositories

```
raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/tigera-operator.yaml
raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/custom-resources.yaml
github.com/projectcalico/calico/releases/download/v3.29.1/calicoctl-linux-amd64
downloads.tigera.io/ee/binaries/v3.19.4/calicoctl
pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key
download.docker.com/linux/ubuntu/gpg
download.docker.com/linux/ubuntu
```

---

### Kubernetes cluster system configuation and initialization

1. Verify the MAC address and product_uuid are unique for every node

You can get the MAC address of the network interfaces using the command ip link or ifconfig -a
The product_uuid can be checked by using the command

`cat /sys/class/dmi/id/product_uuid`


2. Update hosts file on hosts

/etc/hosts

```
10.0.69.41 k8dev-adm01.k8s.cantrellcloud.net
10.0.69.42 k8dev-wkr01.k8s.cantrellcloud.net
10.0.69.43 k8dev-wkr02.k8s.cantrellcloud.net

10.0.69.50 k8prd-lb.k8s.cantrellcloud.net
10.0.69.51 k8prd-adm01.k8s.cantrellcloud.net
10.0.69.52 k8prd-adm02.k8s.cantrellcloud.net
10.0.69.53 k8prd-wkr01.k8s.cantrellcloud.net
10.0.69.54 k8prd-wkr02.k8s.cantrellcloud.net

172.16.69.41 copine-k8adm01.cantrellcloud.net
172.16.69.51 copine-k8nod01.cantrellcloud.net
172.16.69.52 copine-k8nod02.cantrellcloud.net
```

3. turn off swap

`swapoff-a`

4. turn off swap persistent across reboots

`disable swap in --/etc/fstab`

5. update apt index and install packages for kubernetes

```apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg net-tools gnupg
```

6. download public signing key for kubernetes repositories

- If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command

	- `mkdir -p -m 755 /etc/apt/keyrings`

`curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg`

7. add kubernetes apt repository

- This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list

`echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list`

8. update apt index and install kubernetes packages

```
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
```

9. enable kubelet service

- the kubelet will restart every few seconds, as it waits in a crashloop for kubeadm to tell it what to do.

`systemctl enable --now kubelet`

10. Update firewall rules

- enable firewall and add rules

`ufw enable`

- Control Plane rules

```
ufw allow 22/tcp
ufw allow 6443/tcp
ufw allow 2379/tcp
ufw allow 2380/tcp
ufw allow 8080/tcp
ufw allow 10248/tcp
ufw allow 10250/tcp
ufw allow 10259/tcp
ufw allow 10257/tcp
```

- Worker Nodes rules

```
ufw allow 22/tcp
ufw allow 5473/tcp
ufw allow 10250/tcp
ufw allow 10256/tcp
ufw allow 30000:32767/tcp
```

- check firewall status

`ufw status verbose`

11. add command line aliases for frequently used commands

- edit command alias file

`vi ~/.bash_aliases`

- add aliases and make active

```
alias k=kubectl
alias kg='kubectl get'
alias kd='kubectl describe'
alias ka='kubectl apply'
alias kdelf='kubectl delete -f'
alias kl='kubectl logs'
alias kgall='kubectl get all -A'
alias ktn='kubectl top node'
alias ktp='kubectl top pod'

source ~/.bash_aliases
```

12. kernel parameters for containerD

```
tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

tee /etc/sysctl.d/kube.conf <<EOT
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOT

sysctl --system
```

13. Installing Containerd container runtime

- setup Docker’s apt repository

```apt update
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

- Add the repository to Apt sources:

`deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable`

or this way:
		
```
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
tee /etc/apt/sources.list.d/docker.list /dev/null
```

- install containerd

```
apt update
apt install containerd.io -y
```

- configure the system so it starts using systemd as cgroup

`containerd config default | tee /etc/containerd/config.toml >/dev/null 2>&1`

- verify containerd config file

`vi /etc/containerd/config.toml`

> ...
>   [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
>     SystemdCgroup = true

- setup the service to start automatically and check to make sure it is running

```
systemctl restart containerd
systemctl enable containerd
systemctl status containerd
```

14. Pull kubeadm config images and initialize default configuration

- pull kubeadm default config

```
sysctl --system
kubeadm config images pull
```

- initialize default configuration
	- if building an image, this is a good time to take snapshot 1

`kubeadm init`

- Perform next commands as a regular user

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

15. Modify the kubelet ConfigMap

- Should be set, run command to verify cgroupDriver: systemd

`kubectl edit cm kubelet-config -n kube-system`

16. Install Calico network overlay

```
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/custom-resources.yaml -O
kubectl create -f custom-resources.yaml
```

- initialize overlay

`kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml`

- may take a few minutes for all nodes in the cluster to spin up all the networking nodes and **report ready**
	- you can watch by entering the following command
	
	`watch kubectl get pods -n calico-system`

- Configure NSX overlay
	- it is best practice to use manifest (yaml) files which will be added in a future release
	- for now, create config.yaml files for each of the following IPPools to enable NSX overlay

	```
	apiVersion: crd.projectcalico.org/v1
	kind: IPPool
	metadata:
	  name: ippool-vxlan-dev-internal-subnets
	  namespace: dev-internal
	spec:
	  allowedUses:
		- Workload
		- Tunnel
	  blockSize: 26
	  cidr: 192.168.69.0/24
	  ipipMode: Always
	  natOutgoing: true
	  nodeSelector: all()
	  vxlanMode: CrossSubnet
	```

	```
	apiVersion: crd.projectcalico.org/v1
	kind: IPPool
	metadata:
	  name: ippool-vxlan-dev-external-subnets
	  namespace: dev-external
	spec:
	  allowedUses:
		- Workload
		- Tunnel
	  blockSize: 26
	  cidr: 192.168.68.0/24
	  ipipMode: Always
	  natOutgoing: true
	  nodeSelector: all()
	  vxlanMode: CrossSubnet
	```

17. Verify Kubernetes is running

`kubectl get nodes`

if building an image, this is a good time to take snapshot 2

18. Add additional nodes to cluster and labels, taints, and tolerances

- To join nodes, you must fist have a key
- Copy/paste the displayed command to other nodes that are ready to be added to the cluster

`kubeadm token create --print-join-command`

- on each worker node as a regular user

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

- label nodes

`kubectl label node nodename key=value`

- to bash into a pod

`k exec --stdin --tty dev-intdmz-linux-test-65bf85b85d-lnnhw --namespace=dev-external -- /bin/bash`

---

# COCloud Applications

Applications to be added or migrated to Kubernetes

- Unifi controller on kubernetes
	https://medium.com/@reefland/migrating-unifi-network-controller-from-docker-to-kubernetes-5aac8ed8da76
	https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/

- load balancing
	https://github.com/kube-vip/kube-vip-cloud-provider

- kube management
	https://portworx.com/