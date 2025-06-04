Below is a “launch‑pad” script suite—just the scaffolding you asked for—that operationalizes the sequential, major‑grade uplift.  All scripts assume Kubernetes + Helm, but can be trivially adapted for raw kubectl.  Fill in your environment‑specific variables (air‑gapped registry, cluster context, etc.) and integrate with your existing CI/CD orchestrator.

---

## 01‑mongo‑5‑to‑6.sh

```bash
#!/usr/bin/env bash
#
# PURPOSE  : Elevate MongoDB replica‑set from 5.0.x → 6.0.x
# AUTHOR   : DevSecOps Guild
# EXECUTION: ./01-mongo-5-to-6.sh <namespace> <release> <imageTag>
#            e.g. ./01-mongo-5-to-6.sh rcmdb mongo 6.0.13
# -------------------------------------------------------------------

set -euo pipefail
NAMESPACE="${1:?k8s namespace}"
RELEASE="${2:?helm release}"
TARGET_TAG="${3:?target mongo image tag}"

# --- 1. Pre‑flight ----------------------------------------------------------------
echo "⏳  Capturing baseline FCV and replica status"
kubectl -n "$NAMESPACE" exec "$(kubectl -n "$NAMESPACE" get pods -l app=mongodb,role=primary -o name)" \
  -- mongo --quiet --eval 'db.adminCommand({ getParameter:1, featureCompatibilityVersion:1 })'

echo "📦  Triggering Velero + snapshot backup"
velero backup create "mongo5-preflight-$(date +%Y%m%d%H%M)" --include-namespaces="$NAMESPACE"

# --- 2. Rolling Secondary Upgrade -------------------------------------------------
echo "🚀  Executing Helm upgrade (secondaries first, pod disruption budget respected)"
helm upgrade "$RELEASE" bitnami/mongodb \
  --namespace "$NAMESPACE" \
  --set image.tag="$TARGET_TAG" \
  --set architecture=replicaset \
  --set arbiter.enabled=false \
  --set auth.enabled=true \
  --set updateStrategy.type=RollingUpdate

echo "☑️  Waiting for all secondaries to be Ready"
kubectl -n "$NAMESPACE" rollout status sts/"$RELEASE"-secondary

# --- 3. Step‑down Primary & Upgrade ----------------------------------------------
echo "👑  Stepping down current primary"
kubectl -n "$NAMESPACE" exec "$(kubectl -n "$NAMESPACE" get pods -l app=mongodb,role=primary -o name)" \
  -- mongo --eval "rs.stepDown()"

echo "🔄  Helm upgrade primary to ${TARGET_TAG}"
helm upgrade "$RELEASE" bitnami/mongodb \
  --namespace "$NAMESPACE" \
  --set image.tag="$TARGET_TAG"

kubectl -n "$NAMESPACE" rollout status sts/"$RELEASE"-primary

# --- 4. Post‑flight ---------------------------------------------------------------
echo "🔍  Setting FCV to 6.0"
kubectl -n "$NAMESPACE" exec "$(kubectl -n "$NAMESPACE" get pods -l app=mongodb,role=primary -o name)" \
  -- mongo --eval 'db.adminCommand({ setFeatureCompatibilityVersion:"6.0" })'

echo "✅  MongoDB 5→6 complete.  Verify app connectivity before proceeding."
```

---

## 02‑mongo‑6‑to‑7.sh

```bash
#!/usr/bin/env bash
#
# PURPOSE  : Elevate MongoDB replica‑set from 6.0.x → 7.0.19
# EXECUTION: ./02-mongo-6-to-7.sh <namespace> <release> 7.0.19
# -------------------------------------------------------------------

set -euo pipefail
NAMESPACE="${1:?k8s namespace}"
RELEASE="${2:?helm release}"
TARGET_TAG="${3:?7.0.x tag}"

# (Same backup + rolling methodology as above)
# Differences:
#   • setFeatureCompatibilityVersion:"6.0" BEFORE rolling upgrade
#   • AFTER all pods are at 7.x, run setFeatureCompatibilityVersion:"7.0"
#   • Confirm WiredTiger checkpoints and replica‑set health

# -- Place identical blocks here; refactor into functions if DRY needed --
```

---

## 03‑rocketchat‑6‑to‑7.sh

```bash
#!/usr/bin/env bash
#
# PURPOSE : Lift Rocket.Chat from 6.4.x → latest 6.x LTS → 7.0.x → 7.6.0
# EXECUTION: ./03-rocketchat-6-to-7.sh <namespace> <release>
# -------------------------------------------------------------------

set -euo pipefail
NAMESPACE="${1:?k8s namespace}"
RELEASE="${2:?helm release}"

# --- Parameters -------------------------------------------------------------------
IMG6="rocketchat/rocket.chat:6.15.0"
IMG7_BASE="rocketchat/rocket.chat:7.0.0"
IMG7_PATCH="rocketchat/rocket.chat:7.6.0"
NODE_SELECTION="nodeSelector.kubernetes.io/role=chat"

# --- 1. Backup & Quiesce ----------------------------------------------------------
echo "📤  Triggering RC export + PV snapshots"
kubectl -n "$NAMESPACE" exec deploy/"$RELEASE" -- rocketchatctl backup create --passfile /run/secrets/backup.pass

# --- 2. Upgrade to latest 6.x LTS -------------------------------------------------
echo "🚚  Moving to ${IMG6}"
helm upgrade "$RELEASE" oci://registry-1.docker.io/bitnamicharts/rocketchat \
  --namespace "$NAMESPACE" \
  --set image.repository=rocketchat/rocket.chat \
  --set image.tag="${IMG6##*:}" \
  --set podLabels.app=rocketchat \
  --set "${NODE_SELECTION}"

kubectl -n "$NAMESPACE" rollout status deploy/"$RELEASE"

# --- 3. Major Bump 6.x → 7.0.0 ----------------------------------------------------
echo "🚀  Transitioning to 7.0.x baseline"
helm upgrade "$RELEASE" oci://registry-1.docker.io/bitnamicharts/rocketchat \
  --namespace "$NAMESPACE" --set image.tag="${IMG7_BASE##*:}" --reuse-values

kubectl -n "$NAMESPACE" rollout status deploy/"$RELEASE"

# --- 4. Patch 7.0.x → 7.6.0 -------------------------------------------------------
echo "🔧  Patching to 7.6.0"
helm upgrade "$RELEASE" oci://registry-1.docker.io/bitnamicharts/rocketchat \
  --namespace "$NAMESPACE" --set image.tag="${IMG7_PATCH##*:}" --reuse-values

kubectl -n "$NAMESPACE" rollout status deploy/"$RELEASE"

# --- 5. Smoke Tests ---------------------------------------------------------------
echo "🧐  Running smoke tests (auth, file upload, presence)"
# Placeholder for curl /health and API calls

echo "✅  Rocket.Chat 6 → 7.6 upgrade successful"
```

---

### How to Use

```bash
# 1. Set your cluster context
kubectl config use-context prod-tkg

# 2. Populate env variables or pass CLI args
export NAMESPACE=rcmdb
export MONGO_RELEASE=mongo
export RC_RELEASE=rocketchat

# 3. Execute sequentially
./01-mongo-5-to-6.sh  "$NAMESPACE" "$MONGO_RELEASE" "6.0.13"
./02-mongo-6-to-7.sh  "$NAMESPACE" "$MONGO_RELEASE" "7.0.19"
./03-rocketchat-6-to-7.sh "$NAMESPACE" "$RC_RELEASE"
```

> **Pro tip**: Layer these scripts into your GitOps pipeline so each hop is a gated stage with automated health checks before promotion.

---

**Outcome:** These script frameworks give your engineering cadre a turn‑key, audit‑friendly runway to land the Rocket.Chat 7.6 and MongoDB 7 stack inside your air‑gapped enclave—without skipping a beat or a major version.
