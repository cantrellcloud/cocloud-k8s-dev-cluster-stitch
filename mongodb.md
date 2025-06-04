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
