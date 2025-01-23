# cocloud-k8s-dev-cluster-stitch

COCloud K8s Development Cluster Stitch

on Ubuntu 24.04.1 LTS
on Talos Linux 1.9

> Cantrell Cloud Enterprise Services
> 
> designed by:
> 
> Ron Cantrell
> 
> ron@cantrelloffice.cloud
> 

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
+=======================================================================================================+
|                                                                                                      |
|  +===============================================================================================+   |
|  |                                                                                               |   |
|  |  +-----------------------------------------------------------------------------------------+  |   |
|  |  | INGRESS (kube-vip)                                                                      |  |   |
|  |  |                                                                                         |  |   |
|  |  |     +----------------+             +----------------+            +-----------------+    |  |   |
|  |  |     | foo.domain.tld |             | www.domain.ltd |            | app1.domain.ltd |    |  |   |
|  |  |     +----------------+             +----------------+            +-----------------+    |  |   |
|  |  |             |                              |                              |             |  |   |
|  |  +-----------------------------------------------------------------------------------------+  |   |
|  |                |                              |                              |                |   |
|  |                |                              |                              |                |   |
|  |  +---------------------------+  +---------------------------+  +---------------------------+  |   |
|  |  |             |             |  |             |             |  |             |             |  |   |
|  |  |  +---------------------+  |  |  +---------------------+  |  |  +---------------------+  |  |   |
|  |  |  | SERVICE (ClusterIP) +  |  |  | SERVICE (ClusterIP) |  |  |  | SERVICE (ClusterIP) |  |  |   |
|  |  |  +---------------------+  |  |  +---------------------+  |  |  +---------------------+  |  |   |
|  |  |     |       |       |     |  |     |       |       |     |  |     |       |       |     |  |   |
|  |  |     |       |       |     |  |     |       |       |     |  |     |       |       |     |  |   |
|  |  |     \       |       /     |  |     \       |       /     |  |     \       |       /     |  |   |
|  |  |  +-----+ +-----+ +-----+  |  |  +-----+ +-----+ +-----+  |  |  +-----+ +-----+ +-----+  |  |   |
|  |  |  | POD | | POD | | POD |  |  |  | POD | | POD | | POD |  |  |  | POD | | POD | | POD |  |  |   |
|  |  |  +-----+ +-----+ +-----+  |  |  +-----+ +-----+ +-----+  |  |  +-----+ +-----+ +-----+  |  |   |
|  |  |                           |  |                           |  |                           |  |   |
|  |  | WORKER NODE               |  | WORKER NODE               |  | WORKER NODE               |  |   |
|  |  +---------------------------+  +---------------------------+  +---------------------------+  |   |
|  |                                                                                               |   |
|  | KUBERNETES CLUSTER                                                                            |   |
|  +===============================================================================================+   |
|                                                                                                      |
| PACKAGED CLUSTER DEPLOYED ANYWHERE                                                                   |
+======================================================================================================+
```

### Reserved Cluster IP Address Blocks

Example of IP Networks

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

COCloud Networks

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

Talos Linux

### References and Notes

### Repositories

```
raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/tigera-operator.yaml
raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/custom-resources.yaml
github.com/projectcalico/calico/releases/download/v3.29.1/calicoctl-linux-amd64
downloads.tigera.io/ee/binaries/v3.19.4/calicoctl
pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key
download.nerdctl.com/linux/ubuntu/gpg
download.nerdctl.com/linux/ubuntu
```

---

### Talos System Configuation and Initialization

Requirements
	QEMU
	nerdctl
	talosctl
	

registry01

172.16.68.49/27

172.16.68.33

10.0.15.11, 10.0.15.12

install nerdctl
https://github.com/containerd/nerdctl/releases/download/v2.0.2/nerdctl-2.0.2-linux-amd64.tar.gz
tar Cxzvvf /usr/local /home/coadminlocal/nerdctl-2.0.2-linux-amd64.tar.gz

install Talos Linux CLI
curl -sL https://talos.dev/install | sh

Identify Required Talos Images
talosctl image default

Prepare Internal Registry
nerdctl run -d -p 6000:5000 --restart always --name registry-airgapped registry:2
 1bf09802bee1476bc463d972c686f90a64640d87dacce1ac8485585de69c91a5
for image in `talosctl image default`; do nerdctl pull $image; done
for image in `talosctl image default`; do \
    nerdctl tag $image `echo $image | sed -E 's#^[^/]+/#127.0.0.1:6000/#'`; \
	done

for image in `talosctl image default`; do \
    nerdctl push `echo $image | sed -E 's#^[^/]+/#127.0.0.1:6000/#'`; \
    done

for image in $(cat talosctl-images.list) ; do \
    nerdctl tag $image `echo $image | sed -E 's#^[^/]+/#127.0.0.1:6000/#'`; \
	done



for image in `talosctl image default`; do \
    nerdctl tag $image `echo $image | sed -E 's#^[^/]+/#ccesregistry01.azurecr.io/#'`; \
	done

for image in `talosctl image default`; do \
    nerdctl push `echo $image | sed -E 's#^[^/]+/#ccesregistry01.azurecr.io/#'`; \
    done



Ubuntu Linux

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

```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

```kubectl top node
kubectl top pod
```

Logging

```
kubectl logs -f pod-name-here container-name-here
```

Rollouts

```
kubectl rollout status deployment/my-deployment
kubectl rollout history deployment/my-deployment

kubectl rollout undo deployment/my-deployment
```

Configuring Applications

```
nerdctl run ubuntu
nerdctl build -t ubuntu-sleeper .
nerdctl run ubuntu-sleeper

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

```
kubectl get configmaps
```

Secrets

Dive deep into the world of Kubernetes security with a comprehensive guide to Secret Store CSI Driver.
https://www.youtube.com/watch?v=MTnQW9MxnRI

- Secrets are not encrypted. They are **encoded**.
  - Do not check-in Secret objects to SCM (Github) along with code
- Secrets are not encrypted in ETCD
  - Enable encryption at rest
- Anyone able to create application, deployment, or pods in the name namespace can acces the secrets
  - Configure RBAC
  - Consider third-party Secret provider

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

Cluster Maintenance

```
kubectl drain node-1
kubectl cordon node-2
kubectl uncordon node-1
```

- Cluster Upgrade

  - On Master Node(s)

```
apt-get upgrade -y kubeadm=x.xx.x-xx
kubeadm upgrade apply vx.xx.x

apt-get upgrade -y kubelet=x.xx.x-xx
systemctl restart kubelet

```

  - From a master node, drain nodes one-by-one and perform upgrade

```
kubectl drain node
```

  - From each node after it has been drained and cordoned

```
apt-get upgrade -y kubeadm=x.xx.x-xx
apt-get upgrade -y kubelet=x.xx.x-xx
kubeadm upgrade node config --kubelet-version vx.xx.x
systemctl restart kubelet
```

  - From a master node, uncordon nodes one-by-one after being upgraded

```
kubectl uncordon node
```

Backup

https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster

https://github.com/etcd-io/website/blob/main/content/en/docs/v3.5/op-guide/recovery.md

https://www.youtube.com/watch?v=qRPNuT080Hk

```
kubectl get all --all-namespaces -o yaml > all-deploy-services.yaml
```

  - Backup ETCD Cluster
  
  ```
  ETCDCTL_API=3 etcdctl \
    snapshot save snapshot.db
  ```

Storage

  - Storage Drivers
  
  - Volume Drivers

How to add Azure Files for persistant storage

  - Container storage interface (CSI)

Networking

  - CoreDNS
  
  https://github.com/kubernetes/dns/blob/master/docs/specification.md

  https://coredns.io/plugins/kubernetes/
  
  - Network Namespaces (Linux)
  
  ```
  ip netns add red
  ip netns add blue
 
  ip link add v-net-0 type bridge
  ip link set dev v-net-0 up
  
  ip -n red link del veth-red
  
  ip link add veth-red type veth peer name veth-red-br
  ip link add veth-blue type veth peer name veth-blue-br
  
  ip link set veth-red netns red
  ip link set veth-red-br master v-net-0
  ip link set veth-blue netns blue
  ip link set veth-blue-br master v-net-0
  
  ip -n red addr add <IPADDRESS> dev veth-red
  ip -n blue addr add <IPADDRESS> dev veth-blue

  ip -n red link set veth-red up  
  ip -n blue link set veth-blue up
  
  ip addr add 192.168.15.5/24 dev v-net-0
  
  ip netns exec blue ip route add 192.168.1.0/24 via 192.168.15.5
  iptables -t nat -A POSTROUTING -s 192.168.15.0/24 -j MASQUERADE
  
  ip netns exec blue ip route add default via 192.168.15.5
  ```

  - To forward a port to a namespace on a node
  
  ```
  iptables -t nat -A PREROUTING --dport 80 --to-destination 192.168.15.2:80 -j DNAT
  ```

  - nerdctl Networking
  
  nerdctl network create -d macvlan \
  --subnet=10.0.69.224/27 \
  --gateway=10.0.69.225 \
  -o parent=eth1 \
  unifi
  
  
  - CNI
  
  `/opt/cni/bin`
  
  `/etc/cni`
  
  `ps -aux | grep kubelet | grep --color container-runtime-endpoint`
  
  `kubectl logs -n kube-system`
  

  - Ingress
  Nginx is part of Kube project
  
  get ingress resources
  `kubectl get ingress -A`

  create a namespace
  `kubectl create ns ingress-nginx`
  
  create configmap
  `kubectl create configmap ingress-nginx-controller -ns ingress-nginx`

  create service accounts
  `kubectl create serviceaccount ingress-nginx --namespace ingress-nginx` and
  `kubectl create serviceaccount ingress-nginx-admission --namespace ingress-nginx`
  
  apply ingress-controller.yaml configureation
  
Security

 - Enable SSH based authentication
 
  Certificates used by Kubernetes

  ```
  
  ```

   
  Certificate Authority

  - ca

  ```
  openssl genrsa -out devca.key
  openssl req -new -key devca.key -subj "/CN=Cantrell Cloud Kubernetes CA" -out devca.csr
  
  sign the csr with Cantrell Cloud Signing CA
  ```
   
  Client Certs

  - admin

  ```
  openssl genrsa -out devadmin.key
  openssl req -new -key devadmin.key -subj "/CN=kube-admin/O=system:masters" -out devadmin.csr
  openssl x509 -req -in devadmin.csr -CA devca.crt -CAkey devca.key -out devadmin.crt
  ```
  
  - scheduler

  ```
  openssl genrsa -out devscheduler.key
  openssl req -new -key devscheduler.key -subj "/CN=system:kube-scheduler" -out devscheduler.csr
  openssl x509 -req -in devscheduler.csr -CA devca.crt -CAkey devca.key -out devscheduler.crt
  ```
  
  - controller-manager

  ```
  openssl genrsa -out devcontrollermanager.key
  openssl req -new -key devcontrollermanager.key -subj "/CN=system:kube-controller-manager" -out devcontrollermanager.csr
  openssl x509 -req -in devcontrollermanager.csr -CA devca.crt -CAkey devca.key -out devcontrollermanager.crt
  ```
  
  - kube-proxy

  ```
  openssl genrsa -out devkubeproxy.key
  openssl req -new -key devkubeproxy.key -subj "/CN=system:kube-proxy" -out devkubeproxy.csr
  openssl x509 -req -in devkubeproxy.csr -CA devca.crt -CAkey devca.key -out devkubeproxy.crt
  ```
  
  - apiserver-kublet-client

  ```
  openssl genrsa -out devapikubeletclient1.key
  openssl req -new -key devapikubeletclient1.key -subj "/CN=system:node:kubectrl01/O=system:nodes" -out devapikubeletclient1.csr
  openssl x509 -req -in devapikubeletclient1.csr -CA devca.crt -CAkey devca.key -out devapikubeletclient1.crt
  
  openssl genrsa -out devapikubeletclient1.key
  openssl req -new -key devapikubeletclient1.key -subj "/CN=system:node:kubectrl01/O=system:nodes" -out devapikubeletclient1.csr
  openssl x509 -req -in devapikubeletclient1.csr -CA devca.crt -CAkey devca.key -out devapikubeletclient1.crt
  
  
  ```
  
  - apiserver-etcd-client

  ```
  openssl genrsa -out devadmin.key
  openssl req -new -key devadmin.key -subj "/CN=kube-admin/O=system:masters" -out devadmin.csr
  openssl x509 -req -in devadmin.csr -CA devca.crt -CAkey devca.key -out devadmin.crt
  ```
  
  - kubelet-client

  ```
  openssl genrsa -out devadmin.key
  openssl req -new -key devadmin.key -subj "/CN=kube-admin/O=system:masters" -out devadmin.csr
  openssl x509 -req -in devadmin.csr -CA devca.crt -CAkey devca.key -out devadmin.crt
  ```
  

  Server Certs
  - apiserver

  ```
  openssl genrsa -out devapiserver.key
  openssl req -new -key devapiserver.key -subj "/CN=kube-apiserver" -out devapiserver.csr
  
  use an openssl config file to set the SANs
  
  openssl x509 -req -in devapiserver.csr -CA devca.crt -CAkey devca.key -out devapiserver.crt
  ```
  
  - etcdserver

  ```
  openssl genrsa -out devetcdserver.key
  openssl req -new -key devetcdserver.key -subj "/CN=etcd-server" -out devetcdserver.csr
  openssl x509 -req -in devetcdserver.csr -CA devca.crt -CAkey devca.key -out devetcdserver.crt
  ```
  
  - kubelet

  ```
  openssl genrsa -out devkublet1.key
  openssl req -new -key devkublet1.key -subj "/CN=kubectrl01" -out devkublet1.csr
  openssl x509 -req -in devkublet1.csr -CA devca.crt -CAkey devca.key -out devkublet1.crt
  
  openssl genrsa -out devkublet2.key
  openssl req -new -key devkublet2.key -subj "/CN=kubectrl02" -out devkublet2.csr
  openssl x509 -req -in devkublet2.csr -CA devca.crt -CAkey devca.key -out devkublet2.crt
  
  continue making kublet certs for all nodes in the cluster
  ```
  
  



## Deploying a high availability Kubernetes cluster running the Rocket.Chat application across three data centers involves several key milestones. Here’s a high-level overview:

### 1. **Planning and Design**
- **Requirements Gathering**: Identify the hardware, software, and network requirements.
- **Architecture Design**: Design the architecture, including the layout of the Kubernetes clusters, network topology, and data center interconnections.
- **High Availability Strategy**: Plan for redundancy and failover mechanisms across the three data centers.

### 2. **Infrastructure Setup**
- **Provisioning Resources**: Set up the necessary compute, storage, and network resources in each data center.
- **Networking Configuration**: Configure networking to ensure connectivity between the data centers, including VPNs or dedicated links.

### 3. **Kubernetes Cluster Deployment**
- **Cluster Initialization**: Deploy Kubernetes clusters in each data center using tools like kubeadm, kops, or managed services (e.g., GKE, EKS, AKS).
- **Cluster Federation**: Set up Kubernetes federation or use multi-cluster management tools (e.g., Rancher, Anthos) to manage the clusters across the data centers.

### 4. **Rocket.Chat Deployment**
- **Containerization**: Create nerdctl images for Rocket.Chat and its dependencies (e.g., MongoDB).
- **Helm Charts**: Use Helm charts to define and deploy Rocket.Chat applications across the Kubernetes clusters.
- **Persistent Storage**: Configure persistent storage solutions (e.g., NFS, Ceph) to ensure data availability across the clusters.

### 5. **Load Balancing and Traffic Management**
- **Ingress Controllers**: Deploy ingress controllers (e.g., NGINX, Traefik) to manage incoming traffic.
- **Global Load Balancer**: Set up a global load balancer to distribute traffic across the data centers.

### 6. **Monitoring and Logging**
- **Monitoring Tools**: Deploy monitoring tools (e.g., Prometheus, Grafana) to monitor the health and performance of the clusters and applications.
- **Logging Solutions**: Implement centralized logging solutions (e.g., ELK stack, Fluentd) to collect and analyze logs from all clusters.

### 7. **Security and Compliance**
- **Access Control**: Implement RBAC (Role-Based Access Control) to manage access to the Kubernetes clusters.
- **Network Policies**: Define network policies to control traffic between pods and services.
- **Compliance Checks**: Ensure the deployment complies with relevant security and regulatory standards.

### 8. **Testing and Validation**
- **Functional Testing**: Perform functional testing to ensure Rocket.Chat operates correctly.
- **Failover Testing**: Test failover scenarios to validate high availability and disaster recovery plans.

### 9. **Go-Live and Maintenance**
- **Deployment**: Deploy the Rocket.Chat application to production.
- **Ongoing Maintenance**: Regularly update and maintain the clusters and applications, monitor performance, and address any issues.

Would you like more details on any specific milestone?  
  
  
  

### Repositories

```
raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/tigera-operator.yaml
raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/custom-resources.yaml
github.com/projectcalico/calico/releases/download/v3.29.1/calicoctl-linux-amd64
downloads.tigera.io/ee/binaries/v3.19.4/calicoctl
pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key
download.nerdctl.com/linux/ubuntu/gpg
download.nerdctl.com/linux/ubuntu
```

---

### Kubernetes cluster system configuation and initialization

1. Verify the MAC address and product_uuid are unique for every node

You can get the MAC address of the network interfaces using the command ip link or ifconfig -a
The product_uuid can be checked by using the command

```
cat /sys/class/dmi/id/product_uuid
apt install vim
```

2. Network Configuration

Set Interfaces - only if required

```
# The following will replace current network configuration
# Be sure to change required data before running tee command

tee /etc/netplan/50-cloud-init.yaml <<EOF
network:
    ethernets:
        eth0:
            addresses:
            - 10.0.69.51/27
            nameservers:
                addresses:
                - 172.16.69.71
                - 172.16.69.72
                search:
                - cantrellcloud.net
                - cantrelloffice.cloud
                - cantrell.cloud
            routes:
            -   to: default
                via: 10.0.69.33
        eth1: {}
    version: 2
    vlans:
        eth1.10:
            id: 10
            link: eth1
        eth1.101:
            id: 101
            link: eth1
EOF

netplan try
```

Set NTP Client

```
# The following will replace current network configuration

tee /etc/systemd/timesyncd.conf <<EOF
[Time]
NTP=time.cantrelloffice.cloud
EOF

systemctl restart systemd-timesyncd
wait 1500
timedatectl timesync-status
```

Update hosts File

```
vi /etc/hosts
```

```
10.0.69.50 kube01.cantrellcloud.net
10.0.69.51 kubectrl01.cantrellcloud.net
10.0.69.52 kubectrl02.cantrellcloud.net
10.0.69.53 kubework01.cantrellcloud.net
10.0.69.54 kubework02.cantrellcloud.net
```

3. Disable systemd-networkd-wait-online

```
/lib/systemd/system/systemd-networkd-wait-online.service

 # add TimeoutStartSec=5sec under the [Service] section, e.g.:

[Service]
Type=oneshot
ExecStart=/lib/systemd/systemd-networkd-wait-online
RemainAfterExit=yes
TimeoutStartSec=5sec
```

4. Turn off swap now and make persistent across reboots

```
swapoff-a
```

Make Persistent across reboot; look for swap in --/etc/fstab and put a # in front of it

```
vi /etc/fstab
```

5. Update apt index and install packages for kubernetes

```
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg net-tools gnupg
```

6. Download public signing key for kubernetes repositories

```
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

7. add kubernetes apt repository

This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list

```
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
```

8. update apt index and install kubernetes packages

```
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
```

9. enable kubelet service

the kubelet will restart every few seconds, as it waits in a crashloop for kubeadm to tell it what to do.

```
systemctl enable --now kubelet
```

10. Update firewall rules

enable firewall and add rules

```
apt install -y ufw
```

Control Plane rules

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

Worker Nodes rules

```
ufw allow 22/tcp
ufw allow 5473/tcp
ufw allow 10250/tcp
ufw allow 10256/tcp
ufw allow 30000:32767/tcp
```

```
ufw enable
```

check firewall status

```
ufw status verbose
```

11. add command line aliases for frequently used commands (non-root user)

add aliases and make active

```
tee ~/.bash_aliases <<EOF
alias k=kubectl
alias kg='kubectl get'
alias kd='kubectl describe'
alias ka='kubectl apply'
alias kdelf='kubectl delete -f'
alias kl='kubectl logs'
alias kgall='kubectl get all -A'
alias ktn='kubectl top node'
alias ktp='kubectl top pod'
alias n=nerdctl
alias nil='nerdctl image ls'
alias ncl='nerdctl container ls'
alias nirm='nerdctl image rm'
alias ncrm='nerdctl container rm'
alias ncstart='nerdctl container start'
alias ncstop='nerdctl container stop'
EOF

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
https://github.com/containerd/nerdctl
https://github.com/containerd/containerd/blob/main/docs/getting-started.md


setup nerdctl’s apt repository

download nerdctl binaries
```
cd $HOME
wget https://github.com/containerd/nerdctl/releases/download/v2.0.2/nerdctl-2.0.2-linux-amd64.tar.gz
```

extract nerdctl binaries - only on k8s-controllers

```
tar Cxzvvf /usr/local/bin nerdctl-2.0.2-linux-amd64.tar.gz
```

enable/confirm cgroup v2

```
cat /etc/default/grub | grep systemd.unified_cgroup_hierarchy
```

enable non-root cpu, cpuset, and i/o delegation - run as non-root user on k8s-controllers

```
sudo mkdir -p /etc/systemd/system/user@.service.d
cat <<EOF | sudo tee /etc/systemd/system/user@.service.d/delegate.conf
[Service]
Delegate=cpu cpuset io memory pids
EOF
sudo systemctl daemon-reload

cat /sys/fs/cgroup/user.slice/user-$(id -u).slice/user@$(id -u).service/cgroup.controllers  - run as non-root user on k8s-controllers
```

install containerd

follow this for now: https://github.com/containerd/containerd/blob/main/docs/getting-started.md

```
tar Cxzvf /usr/local containerd-x.x.x-linux-amd64.tar.gz

sudo install -m 755 runc.amd64 /usr/local/sbin/runc

mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz

sudo cp containerd.service /usr/local/lib/systemd/system/

systemctl daemon-reload
systemctl enable --now containerd
```

configure the system so it starts using systemd as cgroup - still need to work on this

```
containerd config default | tee /etc/containerd/config.toml >/dev/null 2>&1
```

verify containerd config file - still need to work on this

```
cat /etc/containerd/config.toml
```

> ...
>   [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
>     SystemdCgroup = true

setup the service to start automatically and check to make sure it is running

```
systemctl restart containerd
systemctl enable containerd
systemctl status containerd
```

14. Pull kubeadm config images and initialize default configuration

pull kubeadm default config - only on one of the controllers

```
sysctl --system
kubeadm config images pull
```

initialize default configuration
- if building an image, this is a good time to take snapshot 1

```
kubeadm init
```

Perform next commands as a regular user

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

15. Modify the kubelet

ConfigMap
Should be set, run command to verify cgroupDriver: systemd

```
kubectl edit cm kubelet-config -n kube-system
```

Labels

```
kubectl label node kubectrl02 node-role.kubernetes.io/control-plane=
kubectl label node kubework01 node-role.kubernetes.io/worker=
```

16. Install Calico network overlay

```
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/tigera-operator.yaml
curl https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/custom-resources.yaml
kubectl create -f custom-resources.yaml
```

initialize overlay

```
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

may take a few minutes for all nodes in the cluster to spin up all the networking nodes and **report ready**
- you can watch by entering the following command
	
	```
	watch kubectl get pods -n calico-system
	```

Configure NSX overlay
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

```
kubectl get nodes
```

if building an image, this is a good time to take snapshot 2

18. Add additional nodes to cluster and labels, taints, and tolerances

To join nodes, you must fist have a key
Copy/paste the displayed output to other nodes that are ready to be added to the cluster

```
kubeadm token create --print-join-command
```

on each worker node as a regular user

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

label nodes

```
kubectl label node nodename key=value
```

to bash into a pod

```
k exec --stdin --tty dev-intdmz-linux-test-65bf85b85d-lnnhw --namespace=dev-external -- /bin/bash
```

---

# COCloud Applications

Applications to be added or migrated to Kubernetes

Unifi controller on kubernetes

	https://medium.com/@reefland/migrating-unifi-network-controller-from-nerdctl-to-kubernetes-5aac8ed8da76
	https://kubernetes.io/docs/reference/command-line-tools-reference/feature-gates/

Load balancing

	https://github.com/kube-vip/kube-vip-cloud-provider

Kube management

	https://portworx.com/

HashiCorp Vault deployed on K8s

	In a future release