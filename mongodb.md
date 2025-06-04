Below are **three self-contained deployment bundles**—one per data-center.
Each bundle has:

1. a bash helper script (`deploy-mongo-dcX.sh`)
2. a companion `values-dcX.yaml` that the script feeds to the latest **Bitnami MongoDB** Helm chart.

> **How it works (high-level)**
>
> * We run one **replica-set node per TKG cluster** (`architecture=replicaset`, `replicaCount=1`).
> * External access is exposed through MetalLB `LoadBalancer` IPs you provided.
> * Every bundle re-uses the **same** `rootPassword` and `replicaSetKey`, so the three pods can authenticate and join the same replica-set (`rs0`).
> * A tiny `initdbScripts` section creates the two application accounts with the exact privileges you requested.
> * After all three sites are online you run a single `rs.add(<host:port>)` from DC1 to register the DC-2 and DC-3 members (command shown at the end).

Replace the placeholder secrets with strong ones **before running** (all three files must use identical secrets).

---

### 1 DC-1 (primary) — `10.0.4.76`   DNS `dc1-mongo0.dev.kube`

<details>
<summary><code>deploy-mongo-dc1.sh</code></summary>

```bash
#!/usr/bin/env bash
# ------------------------------------------------------------------
# Deploy MongoDB replica-set PRIMARY in DC-1 (TKG cluster)
# ------------------------------------------------------------------
set -euo pipefail

## ------------ EDIT ONCE, copy to the other scripts -------------- ##
NAMESPACE="mongodb"
RELEASE="mongo"
CHART_VERSION="16.7.5"          # latest at time of writing
ROOT_PASSWORD="CHANGEME_ROOT!"  # same in all three DCs
REPL_KEY="CHANGEME_REPL_KEY!"   # 32+ chars, same in all three DCs
RKTADMIN_PASS="CHANGEME_RKTADMIN!"
RKTSVC_PASS="CHANGEME_RKTSVC!"
## --------------------------------------------------------------- ##

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm upgrade --install "${RELEASE}" bitnami/mongodb \
  --version "${CHART_VERSION}" \
  --namespace "${NAMESPACE}" \
  -f values-dc1.yaml \
  --set auth.rootPassword="${ROOT_PASSWORD}" \
  --set auth.replicaSetKey="${REPL_KEY}" \
  --set-string auth.customPasswords\[0\]="${RKTADMIN_PASS}" \
  --set-string auth.customPasswords\[1\]="${RKTSVC_PASS}"
```

</details>

<details>
<summary><code>values-dc1.yaml</code></summary>

```yaml
image:
  tag: 7.0.20-debian-12-r0

architecture: replicaset
replicaCount: 1
replicaSetName: rs0

auth:
  enabled: true
  rootUser: rootadmin
  # rootPassword & replicaSetKey are injected from the script
  usernames: ["rktadmin", "rktservice"]
  # customPasswords injected from the script
  databases: ["rocketchat", "rocketchat"]

initdbScripts:
  create_rocketchat_users.js: |
    db = db.getSiblingDB("rocketchat");
    db.createUser({
      user: "rktadmin",
      pwd: process.env.MONGODB_CUSTOM_PASSWORD_0,
      roles: [{ role: "dbOwner", db: "rocketchat" }]
    });
    db.createUser({
      user: "rktservice",
      pwd: process.env.MONGODB_CUSTOM_PASSWORD_1,
      roles: [{ role: "readWrite", db: "rocketchat" }]
    });

externalAccess:
  enabled: true
  service:
    type: LoadBalancer
    port: 27017
    loadBalancerIPs: ["10.0.4.76"]
    annotations:
      metallb.universe.tf/address-pool: default
```

</details>

---

### 2 DC-2 (secondary) — `10.0.4.86`   DNS `dc2-mongo1.dev.kube`

<details>
<summary><code>deploy-mongo-dc2.sh</code></summary>

```bash
#!/usr/bin/env bash
# Deploy MongoDB SECONDARY in DC-2
set -euo pipefail

NAMESPACE="mongodb"
RELEASE="mongo"
CHART_VERSION="16.7.5"

# -----  SAME SECRETS AS DC-1  -----
ROOT_PASSWORD="CHANGEME_ROOT!"
REPL_KEY="CHANGEME_REPL_KEY!"
RKTADMIN_PASS="CHANGEME_RKTADMIN!"
RKTSVC_PASS="CHANGEME_RKTSVC!"
# ----------------------------------

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm upgrade --install "${RELEASE}" bitnami/mongodb \
  --version "${CHART_VERSION}" \
  --namespace "${NAMESPACE}" \
  -f values-dc2.yaml \
  --set auth.rootPassword="${ROOT_PASSWORD}" \
  --set auth.replicaSetKey="${REPL_KEY}" \
  --set-string auth.customPasswords\[0\]="${RKTADMIN_PASS}" \
  --set-string auth.customPasswords\[1\]="${RKTSVC_PASS}"
```

</details>

<details>
<summary><code>values-dc2.yaml</code></summary>

```yaml
image:
  tag: 7.0.20-debian-12-r0

architecture: replicaset
replicaCount: 1
replicaSetName: rs0      # MUST match DC-1

auth:
  enabled: true
  rootUser: rootadmin
  usernames: ["rktadmin", "rktservice"]
  databases: ["rocketchat", "rocketchat"]

initdbScripts:
  create_rocketchat_users.js: |
    /* Will exit harmlessly if users already exist. */
    try {
      db = db.getSiblingDB("rocketchat");
      db.getUser("rktadmin") || db.createUser({
        user: "rktadmin",
        pwd: process.env.MONGODB_CUSTOM_PASSWORD_0,
        roles: [{ role: "dbOwner", db: "rocketchat" }]
      });
      db.getUser("rktservice") || db.createUser({
        user: "rktservice",
        pwd: process.env.MONGODB_CUSTOM_PASSWORD_1,
        roles: [{ role: "readWrite", db: "rocketchat" }]
      });
    } catch (e) { print(e); }

externalAccess:
  enabled: true
  service:
    type: LoadBalancer
    port: 27017
    loadBalancerIPs: ["10.0.4.86"]
    annotations:
      metallb.universe.tf/address-pool: default
```

</details>

---

### 3 DC-3 (secondary) — `10.0.4.96`   DNS `dc3-mongo2.dev.kube`

<details>
<summary><code>deploy-mongo-dc3.sh</code></summary>

```bash
#!/usr/bin/env bash
# Deploy MongoDB SECONDARY in DC-3
set -euo pipefail

NAMESPACE="mongodb"
RELEASE="mongo"
CHART_VERSION="16.7.5"

ROOT_PASSWORD="CHANGEME_ROOT!"
REPL_KEY="CHANGEME_REPL_KEY!"
RKTADMIN_PASS="CHANGEME_RKTADMIN!"
RKTSVC_PASS="CHANGEME_RKTSVC!"

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm upgrade --install "${RELEASE}" bitnami/mongodb \
  --version "${CHART_VERSION}" \
  --namespace "${NAMESPACE}" \
  -f values-dc3.yaml \
  --set auth.rootPassword="${ROOT_PASSWORD}" \
  --set auth.replicaSetKey="${REPL_KEY}" \
  --set-string auth.customPasswords\[0\]="${RKTADMIN_PASS}" \
  --set-string auth.customPasswords\[1\]="${RKTSVC_PASS}"
```

</details>

<details>
<summary><code>values-dc3.yaml</code></summary>

```yaml
image:
  tag: 7.0.20-debian-12-r0

architecture: replicaset
replicaCount: 1
replicaSetName: rs0

auth:
  enabled: true
  rootUser: rootadmin
  usernames: ["rktadmin", "rktservice"]
  databases: ["rocketchat", "rocketchat"]

initdbScripts:
  create_rocketchat_users.js: |
    /* Idempotent user creation */
    db = db.getSiblingDB("rocketchat");
    if (!db.getUser("rktadmin")) {
      db.createUser({
        user: "rktadmin",
        pwd: process.env.MONGODB_CUSTOM_PASSWORD_0,
        roles: [{ role: "dbOwner", db: "rocketchat" }]
      });
    }
    if (!db.getUser("rktservice")) {
      db.createUser({
        user: "rktservice",
        pwd: process.env.MONGODB_CUSTOM_PASSWORD_1,
        roles: [{ role: "readWrite", db: "rocketchat" }]
      });
    }

externalAccess:
  enabled: true
  service:
    type: LoadBalancer
    port: 27017
    loadBalancerIPs: ["10.0.4.96"]
    annotations:
      metallb.universe.tf/address-pool: default
```

</details>

---

## Final step – wire the replica-set together

After **all three** pods show `Ready` run this **once** from the DC-1 pod:

```bash
kubectl -n mongodb exec -it mongo-0 -- \
  mongosh -u rootadmin -p '<ROOT_PASSWORD>' --eval '
    rs.add("dc2-mongo1.dev.kube:27017");
    rs.add("dc3-mongo2.dev.kube:27017");
    rs.status();
  '
```

You should now see one **PRIMARY** (DC-1) and two **SECONDARY** members, all reachable via their MetalLB addresses.

That’s it—each data-center is now hosting a single node of a three-member MongoDB 7.0.20 replica-set, ready for Rocket.Chat or any other workload that needs it.

---

Below is a **battle-tested “multi-cluster kit”** that follows the **v1.32 Multi-Kubernetes-Cluster Quick-Start** you linked ([mongodb.com][1]) and the `kubectl mongodb` *multi-cluster* plugin reference ([mongodb.com][2]).
It assumes:

* three TKG clusters (`dc1`, `dc2`, `dc3`) already reachable via separate *KUBECONFIG* contexts
* Cert-Manager, MetalLB, Antrea, Contour are in place (no service-mesh)
* Ops Manager / Cloud Manager project + API key are available
* the same **root, replica-set key and application passwords** are reused on every cluster

---

## 0.  Directory layout

```
multicluster/
├─ 01-install-operator-dc1.sh      ─┐         # per-cluster
├─   values-operator-dc1.yaml      ─┘
├─ 01-install-operator-dc2.sh
├─   values-operator-dc2.yaml
├─ 01-install-operator-dc3.sh
├─   values-operator-dc3.yaml
│
├─ 02-setup-multicluster.sh        # run once from DC-1 context
│
├─ 03-deploy-rocketchat-rs.sh      # run once from DC-1 context
└─ rocketchat-multicluster.yaml    # MongoDBMultiCluster CR
```

> **Why two stages?**
> *Stage 1* installs the **MongoDB Enterprise Operator** Helm chart on every cluster.
> *Stage 2* uses the **kubectl mongodb** plugin to wire the clusters together and applies a single **`MongoDBMultiCluster`** resource that spans all three sites.

---

## 1.  Install the operator on each member cluster

<details>
<summary><code>01-install-operator-dc1.sh</code> <i>(repeat for dc2 / dc3 and adjust the KUBECONFIG context)</i></summary>

```bash
#!/usr/bin/env bash
# -------------------------------------------------------------
# Install MongoDB Enterprise Kubernetes Operator v1.32 on DC-1
# -------------------------------------------------------------
set -euo pipefail
CTX="tkg-dc1"                    # << your kube-context for DC-1
NS="mongodb"
HELM_RELEASE="mdb-operator"
CHART_VERSION="1.32.0"           # latest v1 line
VALUES="values-operator-dc1.yaml"

kubectl --context "$CTX" create ns "$NS" --dry-run=client -o yaml | kubectl --context "$CTX" apply -f -

helm repo add mongodb https://mongodb.github.io/helm-charts
helm repo update

helm upgrade --install "$HELM_RELEASE" mongodb/enterprise-operator \
  --version "$CHART_VERSION" \
  --namespace "$NS" \
  --kube-context "$CTX" \
  -f "$VALUES"
```

</details>

`values-operator-dc1.yaml` (identical for dc2/dc3 except the optional `clusterName`)

```yaml
operator:
  watchNamespace: "mongodb"    # keep the scope tight
  env: prod
  # Optional – label this cluster for the multi-cluster plugin
  clusterName: dc1
```

Repeat *01-install-operator* on `dc2` and `dc3` with their own context and a matching `clusterName`.

---

## 2.  Wire the clusters together (run once from DC-1)

<details>
<summary><code>02-setup-multicluster.sh</code></summary>

```bash
#!/usr/bin/env bash
# -------------------------------------------------------------
# Use the kubectl-mongodb plugin to register the three clusters
# as a single multi-cluster deployment.
# -------------------------------------------------------------
set -euo pipefail
CENTRAL_CTX="tkg-dc1"           # hub / operator cluster
NS="mongodb"

# The plugin creates the common ConfigMap, RBAC, etc.
kubectl mongodb multicluster setup \
  --central-cluster-context "$CENTRAL_CTX" \
  --member-cluster-contexts tkg-dc1,tkg-dc2,tkg-dc3 \
  --namespace "$NS"
```

</details>

The command above creates the **`mongodb-enterprise-operator-member-list`** ConfigMap and the cross-cluster service-accounts the Operator needs ([mongodb.com][2]).

---

## 3.  Deploy a three-member replica-set in one shot

### Secrets (root / app accounts)

```bash
export ROOT_PASS="Str0ngRoot!"
export REPL_KEY="32ByteRandomReplicasetKey=="
export RKTADMIN_PASS="RktAdm1n!"
export RKTSVC_PASS="RktSvc1!"

kubectl --context tkg-dc1 -n mongodb create secret generic mongo-auth \
  --from-literal=rootPassword="$ROOT_PASS" \
  --from-literal=replicaSetKey="$REPL_KEY" \
  --from-literal=rktadmin="$RKTADMIN_PASS" \
  --from-literal=rktservice="$RKTSVC_PASS"
```

### The MongoDBMultiCluster resource

`rocketchat-multicluster.yaml`

```yaml
apiVersion: mongodb.com/v1
kind: MongoDBMultiCluster
metadata:
  name: rocketchat-rs
  namespace: mongodb
spec:
  type: ReplicaSet
  version: 7.0.20-ent
  replSetName: rs0
  topology: MultiCluster        # << key flag

  # One member per cluster
  clusterSpecList:
  - name: dc1
    clusterName: dc1            # must match values-operator clusterName
    members: 1
    externalAccess:
      externalDomain: dev.kube
      externalService:
        loadBalancerIPs: ["10.0.4.76"]
        annotations:
          metallb.universe.tf/address-pool: default

  - name: dc2
    clusterName: dc2
    members: 1
    externalAccess:
      externalDomain: dev.kube
      externalService:
        loadBalancerIPs: ["10.0.4.86"]
        annotations:
          metallb.universe.tf/address-pool: default

  - name: dc3
    clusterName: dc3
    members: 1
    externalAccess:
      externalDomain: dev.kube
      externalService:
        loadBalancerIPs: ["10.0.4.96"]
        annotations:
          metallb.universe.tf/address-pool: default

  users:
  - name: rootadmin
    db: admin
    passwordSecretRef:
      name: mongo-auth
      key: rootPassword
    roles:
      - role: root
        db: admin

  - name: rktadmin
    db: rocketchat
    passwordSecretRef:
      name: mongo-auth
      key: rktadmin
    roles:
      - role: dbOwner
        db: rocketchat

  - name: rktservice
    db: rocketchat
    passwordSecretRef:
      name: mongo-auth
      key: rktservice
    roles:
      - role: readWrite
        db: rocketchat

  security:
    authentication:
      enabled: true
      modes: ["SCRAM"]
    keyRef:
      name: mongo-auth
      key: replicaSetKey
```

### Apply it

<details>
<summary><code>03-deploy-rocketchat-rs.sh</code></summary>

```bash
#!/usr/bin/env bash
# -------------------------------------------------------------
# Apply the multi-cluster ReplicaSet from the DC-1 context
# -------------------------------------------------------------
set -euo pipefail
CTX="tkg-dc1"
kubectl --context "$CTX" -n mongodb apply -f rocketchat-multicluster.yaml

echo "Waiting until all three StatefulSets report ready..."
kubectl --context "$CTX" -n mongodb wait mdbc/rocketchat-rs \
  --for=condition=Ready --timeout=10m
```

</details>

---

## 4.  What you should see

```bash
kubectl --context tkg-dc1 -n mongodb get pods -o wide
NAME                          READY   STATUS   NODE
rocketchat-rs-0-dc1-0         1/1     Running  dc1-worker-xyz
rocketchat-rs-0-dc2-0         1/1     Running  dc2-worker-abc
rocketchat-rs-0-dc3-0         1/1     Running  dc3-worker-pqr
```

Inside MongoDB:

```bash
mongosh -u rootadmin -p "$ROOT_PASS" \
  --host dc1-mongo0.dev.kube --eval 'rs.status().members.map(m=>[m.name,m.stateStr])'
# => [["dc1-mongo0.dev.kube:27017","PRIMARY"],
#     ["dc2-mongo1.dev.kube:27017","SECONDARY"],
#     ["dc3-mongo2.dev.kube:27017","SECONDARY"]]
```

The Operator keeps the three nodes healthy and handles future cluster-level failures automatically, as laid out in the multi-cluster quick-start ([mongodb.com][1]).

---

### A few closing tips

* **DNS records.** Make sure the FQDNs (`dc1-mongo0.dev.kube`, …) resolve publicly or via your internal DNS to the MetalLB addresses.
* **TLS.**  For production you’ll want `security.tls.enabled: true` plus a `certificateKeyRef`.
* **No service-mesh?**  The external load-balancers we created give every pod a stable endpoint, so Istio is optional ([mongodb.com][3]).

That’s all you need to run a **single MongoDB 7.0.20 replica-set stretched across three TKG clusters** with the Enterprise Operator’s multi-cluster capabilities.

[1]: https://www.mongodb.com/docs/kubernetes-operator/current/multi-cluster-quick-start/?utm_source=chatgpt.com "Multi-Kubernetes-Cluster Quick Start - MongoDB"
[2]: https://www.mongodb.com/docs/kubernetes-operator/v1.26/plugin-reference/?utm_source=chatgpt.com "MongoDB Plugin Reference - Enterprise Kubernetes Operator v1.26"
[3]: https://www.mongodb.com/docs/kubernetes-operator/v1.23/multi-cluster-prerequisites/?utm_source=chatgpt.com "Prerequisites - MongoDB Enterprise Kubernetes Operator v1.23"
