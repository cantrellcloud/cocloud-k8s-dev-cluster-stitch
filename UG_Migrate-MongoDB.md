Here's a detailed, step-by-step procedure to migrate your MongoDB 5.0.23 replica set database running in Docker on RHEL 8 to a MongoDB 5.0.23 replica set on a VMware Tanzu Kubernetes Grid (TKG) workload cluster.

---

### **Pre-requisites**

* Ensure you have sufficient access and permissions to both RHEL VM and Kubernetes cluster.
* Your Kubernetes cluster must have PersistentVolumes (PVs) configured.
* Ensure MongoDB Kubernetes deployment is ready and replica set initialized (`rs0`).

---

## Step-by-Step Migration Procedure

### **1. Pre-Migration Preparation**

**On Source RHEL 8 VM (Docker Environment):**

* Identify MongoDB Container Name:

  ```bash
  docker ps | grep mongo
  ```

* Note container name/id, for example, `mongo-container`.

* Backup the existing MongoDB database.

  ```bash
  docker exec -it mongo-container mongodump --uri="mongodb://localhost:27017/?replicaSet=rs0" --oplog -o /backup/mongodump
  ```

  This creates a dump in `/backup/mongodump`.

* Archive the backup:

  ```bash
  tar -czvf mongodump.tar.gz -C /backup mongodump
  ```

* Transfer the backup archive (`mongodump.tar.gz`) securely to a jump host or directly to a node accessible from your Kubernetes cluster.

---

### **2. Transfer and Restore to Kubernetes MongoDB Replica Set**

**On Kubernetes (TKG Workload Cluster):**

* Copy the `mongodump.tar.gz` file to the Kubernetes environment or a shared volume accessible from MongoDB pods.

* Decompress the archive in the Kubernetes accessible path:

  ```bash
  tar -xzvf mongodump.tar.gz
  ```

* Identify the running MongoDB primary pod name:

  ```bash
  kubectl get pods -l app=mongodb -o wide
  ```

  Example pod output:

  ```
  NAME             READY   STATUS    RESTARTS   AGE   IP
  mongodb-0        1/1     Running   0          12h   10.0.15.10
  mongodb-1        1/1     Running   0          12h   10.0.15.11
  mongodb-2        1/1     Running   0          12h   10.0.15.12
  ```

  Typically, pick `mongodb-0` if primary, verify with:

  ```bash
  kubectl exec -it mongodb-0 -- mongo --eval "rs.isMaster()"
  ```

* Copy the decompressed dump to the primary pod:

  ```bash
  kubectl cp mongodump mongodb-0:/tmp/mongodump
  ```

---

### **3. Restoring MongoDB Data**

* Run restore command on the Kubernetes MongoDB primary pod:

  ```bash
  kubectl exec -it mongodb-0 -- mongorestore --uri="mongodb://localhost:27017/?replicaSet=rs0" --oplogReplay --drop /tmp/mongodump
  ```

  * `--oplogReplay` ensures consistency.
  * `--drop` clears existing data first (use cautiously).

---

### **4. Post-Restore Validation**

* Confirm restoration and integrity of the data by connecting to MongoDB:

  ```bash
  kubectl exec -it mongodb-0 -- mongo
  ```

  Inside Mongo shell:

  ```javascript
  rs.status() // Verify replica set health
  show dbs    // Confirm database presence
  use rocketchat
  show collections
  db.users.find().limit(1)  // Quick data check
  exit
  ```

---

### **5. Point Rocket.Chat Kubernetes deployment to new MongoDB Replica Set**

* Update Rocket.Chat Kubernetes deployment environment variables to point to the restored MongoDB Replica Set:

  Example snippet from Rocket.Chat deployment YAML:

  ```yaml
  env:
  - name: MONGO_URL
    value: "mongodb://mongodb-0.mongodb,mongodb-1.mongodb,mongodb-2.mongodb:27017/rocketchat?replicaSet=rs0&readPreference=primaryPreferred&w=majority"
  - name: MONGO_OPLOG_URL
    value: "mongodb://mongodb-0.mongodb,mongodb-1.mongodb,mongodb-2.mongodb:27017/local?replicaSet=rs0&readPreference=primaryPreferred"
  ```

* Apply updated Rocket.Chat deployment configuration:

  ```bash
  kubectl apply -f rocketchat-deployment.yaml
  ```

---

### **6. Final Verification**

* Check Rocket.Chat pods are running properly:

  ```bash
  kubectl get pods -l app=rocketchat
  ```

* Verify Rocket.Chat logs and operation:

  ```bash
  kubectl logs -f <rocketchat-pod-name>
  ```

* Perform UI-level testing to confirm successful connection and data integrity.

---

## **Cleanup and Archive**

* After successful migration, retain the backup (`mongodump.tar.gz`) for rollback or archival purposes.

---

### **Rollback Procedure (If Required)**

If migration verification fails, rollback by reverting Rocket.Chat to previous MongoDB instance and troubleshooting before another attempt.

---

### **Summary**

This detailed migration procedure safely transitions MongoDB data from a Docker environment on RHEL 8 to a VMware Tanzu Kubernetes Grid environment while maintaining data integrity and minimal downtime.
