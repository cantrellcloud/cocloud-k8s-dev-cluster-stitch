# mongod.conf
# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# where and how to store data.
storage:
  dbPath: /bitnami/mongodb/data/db
  directoryPerDB: false

# where to write logging data.
systemLog:
  destination: file
  quiet: false
  logAppend: true
  logRotate: reopen
  path: /opt/bitnami/mongodb/logs/mongodb.log
  verbosity: 0

# network interfaces
net:
  port: 27017
  unixDomainSocket:
    enabled: true
    pathPrefix: /opt/bitnami/mongodb/tmp
  ipv6: false
  bindIpAll: true
  #bindIp:

# replica set options
replication:
  replSetName: rsRocketchat
  enableMajorityReadConcern: true

# sharding options
#sharding:
  #clusterRole:

# process management options
processManagement:
   fork: false
   pidFilePath: /opt/bitnami/mongodb/tmp/mongodb.pid

# set parameter options
setParameter:
   enableLocalhostAuthBypass: false

# security options
security:
  authorization: enabled
  keyFile: /opt/bitnami/mongodb/conf/keyfile

---

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mongodb-conf
data:
  mongodb.conf: |
    # replica set options
    replication:
      replSetName: rsRocketchat
      enableMajorityReadConcern: true

    # security options
    security:
      authorization: enabled
      keyFile: /opt/bitnami/mongodb/conf/keyfile
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
  labels:
    app: bitnami-mongodb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bitnami-mongodb
  template:
    metadata:
      labels:
        app: bitnami-mongodb
    spec:
      containers:
        - name: mongodb
          image: bitnami/mongodb:latest
          # other env/ports/args as needed...
          volumeMounts:
            - name: mongodb-config
              mountPath: /opt/bitnami/mongodb/conf/mongodb.conf
              subPath: mongodb.conf
      volumes:
        - name: mongodb-config
          configMap:
            name: mongodb-conf
```

---

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mongodb-keyfile-secret
type: Opaque
stringData:
  keyfile: |
    hPV0d4T1VrVmFjMWRVU2
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
  labels:
    app: bitnami-mongodb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bitnami-mongodb
  template:
    metadata:
      labels:
        app: bitnami-mongodb
    spec:
      containers:
        - name: mongodb
          image: bitnami/mongodb:latest
          # ... (other env/ports/args as needed) ...
          volumeMounts:
            - name: mongodb-keyfile
              mountPath: /opt/bitnami/mongodb/conf/keyfile
              subPath: keyfile
      volumes:
        - name: mongodb-keyfile
          secret:
            secretName: mongodb-keyfile-secret
```




hPV0d4T1VrVmFjMWRVU2
