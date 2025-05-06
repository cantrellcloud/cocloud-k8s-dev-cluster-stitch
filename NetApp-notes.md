# NetApp-notes

```bash
NAMESPACE=svc-contour-domain-c45722
kubectl get namespace svc-contour-domain-c45722 -o json |jq '.spec = {"finalizers":[]}' >temp.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/svc-contour-domain-c45722/finalize
```

https://docs.netapp.com/us-en/trident/trident-use/ontap-nas-examples.html

https://github.com/NetApp/trident/releases/download/v25.02.1/trident-installer-25.02.1.tar.gz

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: basic
  labels:
    bryan: death
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1000Gi
  storageClassName: gildo-basic-nas
```

```bash
kubectl get pod -A |grep apshot
```

```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: csi-snapclass
driver: csi.trident.netapp.io
deletionPolicy: Delete
```

https://knowledge.broadcom.com/external/article/375605/containers-unable-to-modifysee-file-perm.html

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment-changeme
spec:
  replicas: 1 
  selector:
    matchLabels:
      SomeLabel: nginx-changeme
  template:
    metadata:
      labels:
        SomeLabel: nginx-changeme    
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: nfsvol 
          mountPath: /www/data
      volumes:
        - name: nfsvol
          persistentVolumeClaim:
            claimName: basic2
```

https://docs.netapp.com/us-en/trident/trident-get-started/kubernetes-deploy-helm-mirror.html

```bash
--set kubeletDir="/var/lib/kubelet"
```

Tanzu makes it kind of a pain compared to other k8s distros where I'd just throw it out on the worker nodes.
🙂 So the article is about how to edit the idmapd.conf file and get it onto the worker nodes initially.

Just need whatever domain you use for the worker nodes to be set on the nfsv4iddomain on the netapp.

https://docs.netapp.com/us-en/ontap/nfs-admin/specify-user-id-domain-nfsv4-task.html

https://kb.netapp.com/on-prem/ontap/da/NAS/NAS-KBs/What_is_an_NFS_-v4-domain-id

The good news is you can just make up a domain randomly, it doesn't have to exist in DNS or AD or anything.  The clients and workers just have to match.
