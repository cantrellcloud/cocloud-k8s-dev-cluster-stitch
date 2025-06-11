Below is a bash script that will:

1. Pull each MongoDB Enterprise Operator–related image from `quay.io/mongodb/…`
2. Retag it under your internal registry `kuberegistry.dev.kube/library/…`
3. Push it to your internal registry

Save this as `mirror-mongodb-operator-images.sh`, make it executable (`chmod +x`), then run it on a host with Docker (or Podman) installed and authenticated against both registries.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Internal registry hostname (no trailing slash)
INTERNAL_REG="kuberegistry.dev.kube/library"

# List of upstream images to mirror
IMAGES=(
  "quay.io/mongodb/mongodb-enterprise-operator-ubi:1.33.0"
  "quay.io/mongodb/mongodb-agent-ubi:1.33.0"
  "quay.io/mongodb/mongodb-enterprise-database-ubi:1.33.0"
  "quay.io/mongodb/mongodb-enterprise-init-database-ubi:1.33.0"
  "quay.io/mongodb/mongodb-enterprise-init-appdb-ubi:1.33.0"
  "quay.io/mongodb/mongodb-enterprise-appdb:10.2.15.5958-1_4.2.11"
  "quay.io/mongodb/mongodb-enterprise-ops-manager-ubi:1.33.0"
  "quay.io/mongodb/mongodb-enterprise-init-ops-manager-ubi:1.33.0"
)

echo "✅ Starting mirror of MongoDB Enterprise Operator images"
for SRC_IMAGE in "${IMAGES[@]}"; do
  echo
  echo "→ Processing ${SRC_IMAGE}"
  # pull from upstream
  docker pull "${SRC_IMAGE}"

  # derive image path under internal registry:
  #   strip everything up to the first '/', then prepend INTERNAL_REG/
  # e.g. "quay.io/mongodb/foo:tag" → "foo:tag"
  IMAGE_PATH="${SRC_IMAGE#*/}"
  TARGET_IMAGE="${INTERNAL_REG}/${IMAGE_PATH}"

  echo "   tagging → ${TARGET_IMAGE}"
  docker tag "${SRC_IMAGE}" "${TARGET_IMAGE}"

  echo "   pushing → ${TARGET_IMAGE}"
  docker push "${TARGET_IMAGE}"
done

echo
echo "🎉 All images mirrored to ${INTERNAL_REG}"
```

**How it works**

* `IMAGES`: an array of all required upstream images with their exact tags.
* In the loop, we pull each image, then use `${SRC_IMAGE#*/}` to strip the registry prefix (everything up through the first slash), so

  ```
  quay.io/mongodb/mongodb-enterprise-operator-ubi:1.33.0
            ↓ strip →       mongodb-enterprise-operator-ubi:1.33.0
  ```
* We then prepend your internal registry (`kuberegistry.dev.kube/library`) and retag/push.

You can adjust `INTERNAL_REG` if your internal registry path changes.
