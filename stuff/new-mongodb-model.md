You **can** drive the entire `rs.initiate(…)`/`rs.reconfig(…)` logic via the chart’s **`replicaSetConfigurationSettings`** section. In other words, instead of relying on the “external‐mode” (`mode: primary/secondary`, `primaryHost`, etc.), you can explicitly list out each member (with its `_id`, `host`, and any other settings) under `replicaSetConfigurationSettings.configuration.members`. When the chart’s entrypoint sees `replicaSetConfigurationSettings.enabled: true`, it will mount a custom script that runs exactly what you’ve defined.

Below is a minimal example of how to do this in a cross‐data‐center scenario. Assume you want exactly three pods—one in each DC—and you already have (or will expose) a DNS record so that:

* DC1’s pod is reachable as `mongo-dc1.mongodb.svc.cluster.local:27017`
* DC2’s pod is reachable as `mongo-dc2.mongodb.svc.cluster.local:27017`
* DC3’s pod is reachable as `mongo-dc3.mongodb.svc.cluster.local:27017`

---

## Example `values.yaml`

```yaml
## 1. Tell Bitnami we want a ReplicaSet architecture
architecture: replicaset
replicaCount: 3

## 2. Put all three pods into ONE release (so that 'helm install' creates
##    mongo-0, mongo-1, mongo-2 in the same namespace). If you prefer
##    separate Helm releases per DC, see note below.
##
##    The important bit is: replicas=3, so the chart creates
##    - mongo-0 (DC1)
##    - mongo-1 (DC2)
##    - mongo-2 (DC3)

## 3. Standard auth settings (same root user/key everywhere!)
mongodb:
  auth:
    enabled: true
    rootUser: root
    rootPassword: VeryStrongRootSecret123
    # You *must* supply a replica‐set key (same across all members).
    replicaSetKey: myVerySecretReplKey  

  ## 4. Override default “auto‐generated” member list by explicitly
  ##    telling the chart to use your own rs.initiate(...) configuration.
  ##
  ##    Note: the chart uses this block to generate a JS snippet that runs
  ##    during the init phase. Each “host” here must be the full FQDN:port
  replicaSetConfigurationSettings:
    enabled: true
    configuration:
      _id: rs0
      members:
        - _id: 0
          host: mongo-0.mongo-headless.default.svc.cluster.local:27017
          priority: 3
        - _id: 1
          host: mongo-1.mongo-headless.default.svc.cluster.local:27017
          priority: 2
        - _id: 2
          host: mongo-2.mongo-headless.default.svc.cluster.local:27017
          priority: 1

## 5. By default, Bitnami will create a Headless Service called “mongo-headless”:
##    you can override if needed:
service:
  headless:
    enabled: true
    name: mongo-headless
    port: 27017

## 6. Persistence / Storage, one PVC per pod:
persistence:
  enabled: true
  size: 50Gi
  storageClass: your-storage-class-here

## 7. (Optional) Set podAntiAffinity so that pods spread across nodes:
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app.kubernetes.io/name: mongodb
            app.kubernetes.io/instance: <release-name>
        topologyKey: "failure-domain.beta.kubernetes.io/zone"
```

**What happens under the hood**

1. Because `architecture: replicaset` and `replicaCount: 3`, Helm renders three StatefulSet pods:

   * `mongo-0`
   * `mongo-1`
   * `mongo-2`
     (By default those pods become `mongo-0.mongo-headless.default.svc.cluster.local`, etc.)
2. The `replicaSetConfigurationSettings.enabled: true` block causes the chart to generate a script like:

   ```js
   // /docker-entrypoint-initdb.d/rs-init.js
   (function() {
     const cfg = {
       _id: "rs0",
       members: [
         { _id: 0, host: "mongo-0.mongo-headless.default.svc.cluster.local:27017", priority: 3 },
         { _id: 1, host: "mongo-1.mongo-headless.default.svc.cluster.local:27017", priority: 2 },
         { _id: 2, host: "mongo-2.mongo-headless.default.svc.cluster.local:27017", priority: 1 }
       ]
     };
     try {
       const status = rs.status();
       if (status.ok && status.set === "rs0") {
         print("Replica set already initiated; skipping.");
       } else {
         print("Initiating replica set with config:", JSON.stringify(cfg));
         rs.initiate(cfg);
       }
     } catch (e) {
       print("Error in RS init script:", e);
     }
   })();
   ```

   When `mongo-0` (i.e. pod with `_id: 0`) starts up first and sees no existing RS, it runs `rs.initiate(cfg)` with exactly the three members you listed.
3. As soon as `mongo-0` boots and becomes primary, it will reach out to `mongo-1` and `mongo-2` at the exact hostnames/IDs you supplied, so you end up with:

   * `mongo-0` as `_id: 0`
   * `mongo-1` as `_id: 1`
   * `mongo-2` as `_id: 2`

---

## Deploying “One Pod per Data Center”

The above example assumes a single Helm release with three replicas in one Kubernetes “fault-domain” (e.g., three pods on three nodes or zones). If you truly have **three discrete Kubernetes clusters** (DC1, DC2, DC3), you have two main options:

1. **Single Release, Federated DNS (preferred).**

   * Install the chart once, but use a multi‐cluster/DNS solution (e.g., Kubernetes ServiceExport/ServiceImport, or ExternalDNS) so that all three pods advertise the same headless service name.
   * Example:

     * In DC1: apply the StatefulSet, create a `ServiceExport` for `mongo-headless.default.svc` (so that DC2/DC3 can resolve `mongo-0.mongo-headless.default.svc.cluster.local`, etc.).
     * In DC2 and DC3: switch contexts and let each install the same three‐replica StatefulSet. Kubernetes (via Submariner/Lighthouse or another DNS layer) will map the headless service such that `mongo-0.mongo-headless.default.svc.cluster.local` always points to the pod in DC1, etc.
   * Finally, all three pods join the same RS by referring to the shared headless service DNS.

2. **Three Separate Releases (“external mode” + `replicaSetConfigurationSettings`).**

   * In **DC1**, you install with `replicaCount: 1` and set `replicaSetConfigurationSettings` exactly as above (pointing to three hostnames, using DNS or public IPs for each pod). That init‐script runs `rs.initiate(…)`.
   * In **DC2 & DC3**, you also install with `replicaCount: 1`, but you do **not** run a second `rs.initiate` (or you guard it). Instead, you use *either*

     * The same `replicaSetConfigurationSettings`, but in DC2 & DC3 you set `extraEnvVars:` so that those pods wait until DC1’s init is done (very fragile unless you script it), or
     * **The “external replicaSet” method** (`mode: secondary + primaryHost: <DC1-pod-DNS>`), so that the DC2/DC3 pod sees DC1 as “primary,” automatically runs `rs.add(...)` under the hood, and joins the set with `_id: 1` or `_id: 2`.

   If you go with **`replicaSetConfigurationSettings` in all three releases**, you risk a race (all three pods might try to do `rs.initiate(cfg)` simultaneously). To avoid that, you usually:

   * In DC1’s release:

     ```yaml
     replicaSetConfigurationSettings:
       enabled: true
       configuration:   # full 3‐member list with _id:0,1,2
     ```
   * In DC2 & DC3: either

     * supply a scaled‐down init script that only does `rs.add(...)` (no `rs.initiate`), or
     * fallback to the “external mode” fields (`mode: secondary`, `primaryHost: …`, `hosts: […]`, etc.) instead of using `replicaSetConfigurationSettings.enabled` at all.

---

## Key Caveats

1. **DNS/Networking Must Reach Across DCs.**
   Whether you use pure `replicaSetConfigurationSettings` or the “external mode,” each pod’s `host: …` entry must resolve to the correct pod across data centers. In multi‐cluster setups, that typically means using ServiceExport/ServiceImport (Lighthouse, CoreDNS federation, ExternalDNS, or similar).
2. **Member `_id` Values Come From Your Block.**
   The chart will **exactly** honor the `_id` you list under `members:`. If you say `_id: 0/1/2` for “mongo-0”, “mongo-1”, “mongo-2,” that mapping is used verbatim.
3. **Priorities / Votes / Hidden, etc.**
   You can also set `priority`, `votes`, or `hidden` in each `members:` entry if you need fine control (e.g., preference for local primaries, read-only tertiaries, etc.).
4. **Only One `rs.initiate(...)` Should Run.**
   If you try to have **all three pods** run the same “init script,” you risk a race. Best practice is:

   * Let your “DC1 pod” do the full `rs.initiate(...)`.
   * DC2/DC3 only run a script that does `rs.add(...)`.
   * Or, use “external mode” for DC2/DC3 so that they automatically add themselves.

---

## Sample (Three Separate Releases, Pure `replicaSetConfigurationSettings`)

Below is a **three‐release** approach (one chart per DC). In each `values.yaml`, you *must* tell the chart:

* Which pods are members (all three hostnames, with `_id` 0,1,2), and
* In DC1: run `rs.initiate(...)` only (so `initiateMode: primary`),
* In DC2/DC3: do not re‐initiate; just run `rs.add(...)`.

### DC1’s `values-dc1.yaml`

```yaml
architecture: replicaset
replicaCount: 1

mongodb:
  auth:
    enabled: true
    rootUser: root
    rootPassword: VeryStrongRootSecret123
    replicaSetKey: myVerySecretReplKey

  ## DC1 is “primary,” so we allow rs.initiate
  replicaSetConfigurationSettings:
    enabled: true
    runMode: primary
    configuration:
      _id: rs0
      members:
        - _id: 0
          host:  mongo-dc1.default.svc.cluster.local:27017
          priority: 3
        - _id: 1
          host:  mongo-dc2.default.svc.cluster.local:27017
          priority: 2
        - _id: 2
          host:  mongo-dc3.default.svc.cluster.local:27017
          priority: 1

service:
  name: mongo-dc1
  port: 27017

persistence:
  enabled: true
  storageClass: fast-ssd
  size: 50Gi
```

### DC2’s `values-dc2.yaml`

```yaml
architecture: replicaset
replicaCount: 1

mongodb:
  auth:
    enabled: true
    rootUser: root
    rootPassword: VeryStrongRootSecret123
    replicaSetKey: myVerySecretReplKey

  ## DC2 is “secondary.” We do NOT call rs.initiate here.
  replicaSetConfigurationSettings:
    enabled: true
    runMode: secondary
    configuration:
      _id: rs0
      members:
        - _id: 0
          host:  mongo-dc1.default.svc.cluster.local:27017
          priority: 3
        - _id: 1
          host:  mongo-dc2.default.svc.cluster.local:27017
          priority: 2
        - _id: 2
          host:  mongo-dc3.default.svc.cluster.local:27017
          priority: 1

service:
  name: mongo-dc2
  port: 27017

persistence:
  enabled: true
  storageClass: fast-ssd
  size: 50Gi
```

### DC3’s `values-dc3.yaml`

```yaml
architecture: replicaset
replicaCount: 1

mongodb:
  auth:
    enabled: true
    rootUser: root
    rootPassword: VeryStrongRootSecret123
    replicaSetKey: myVerySecretReplKey

  ## DC3 is “secondary” as well
  replicaSetConfigurationSettings:
    enabled: true
    runMode: secondary
    configuration:
      _id: rs0
      members:
        - _id: 0
          host:  mongo-dc1.default.svc.cluster.local:27017
          priority: 3
        - _id: 1
          host:  mongo-dc2.default.svc.cluster.local:27017
          priority: 2
        - _id: 2
          host:  mongo-dc3.default.svc.cluster.local:27017
          priority: 1

service:
  name: mongo-dc3
  port: 27017

persistence:
  enabled: true
  storageClass: fast-ssd
  size: 50Gi
```

With this setup:

1. **Install DC1** with

   ```bash
   helm install mongo-dc1 bitnami/mongodb \
     --namespace mongo-ns --create-namespace \
     --values values-dc1.yaml
   ```

   The pod `mongo-dc1` will start, see `runMode: primary`, and run exactly:

   ```js
   rs.initiate({
     _id: "rs0",
     members: [
       { _id: 0, host: "mongo-dc1.default.svc.cluster.local:27017", priority:3 },
       { _id: 1, host: "mongo-dc2.default.svc.cluster.local:27017", priority:2 },
       { _id: 2, host: "mongo-dc3.default.svc.cluster.local:27017", priority:1 }
     ]
   });
   ```
2. Once DC1 is `SECONDARY`/`PRIMARY` and fully up, **install DC2**:

   ```bash
   helm install mongo-dc2 bitnami/mongodb \
     --namespace mongo-ns \
     --values values-dc2.yaml
   ```

   Because `runMode: secondary`, the chart will not do `rs.initiate` again. Instead it will run a script that essentially calls:

   ```js
   rs.add({
     _id: 1,
     host: "mongo-dc2.default.svc.cluster.local:27017",
     priority: 2
   });
   ```
3. Finally, **install DC3** in the same way. DC3’s pod runs a script that does:

   ```js
   rs.add({
     _id: 2,
     host: "mongo-dc3.default.svc.cluster.local:27017",
     priority: 1
   });
   ```

At the end, you have exactly:

```
rs0:PRIMARY> rs.status()
{
  set: "rs0",
  members: [
    { _id: 0, name: "mongo-dc1.default.svc.cluster.local:27017", stateStr: "PRIMARY", priority: 3, … },
    { _id: 1, name: "mongo-dc2.default.svc.cluster.local:27017", stateStr: "SECONDARY", priority: 2, … },
    { _id: 2, name: "mongo-dc3.default.svc.cluster.local:27017", stateStr: "SECONDARY", priority: 1, … }
  ]
}
```

---

### When You Might **NOT** Use `replicaSetConfigurationSettings`

* If you already have a perfectly working single‐release, multi‐zone cluster (roofed by a single headless service), you could instead simply use the “external mode” approach (shown in the earlier answer). That requires fewer YAML lines (no custom `initdb` script).
* If your only goal is to “join three pods in the same Kubernetes StatefulSet,” the chart’s default behavior (when you set `architecture: replicaset` and `replicaCount: 3`) will automatically do a vanilla `rs.initiate(...)` with three members as `mongo-0,mongo-1,mongo-2`. In that scenario, you only need to worry about “multi‐DC” if your pods actually land in different zones or clusters.

---

## Summary

* **Yes**, `replicaSetConfigurationSettings` can absolutely be used to configure a three-node ReplicaSet across three distinct data centers.
* By flipping on `replicaSetConfigurationSettings.enabled: true` and giving a custom `configuration.members` block, you explicitly tell Bitnami’s entrypoint exactly which `_id`, `host`, and `priority` each member should have.
* The **key requirements** are:

  1. All three `(host:port)` addresses must be resolvable (using whatever cross-DC DNS or public‐IP routing you’ve chosen).
  2. Exactly one of your three pods must run the `rs.initiate(...)` (i.e. “runMode: primary”), while DC2/DC3 run only `rs.add(...)` (i.e. “runMode: secondary”).
  3. Use the **same** `replicaSetKey` and `rsName` (`_id: "rs0"`) everywhere.
  4. Make sure your StatefulSet’s headless Service (e.g. `mongo-headless`) exposes the correct DNS names.

If you do all of the above, your DC2 pod will come up as `_id: 1` and DC3 as `_id: 2` with no manual postinstall reconfig steps.

---

#### References

* The Medium.com example (Bitnami chart + multi‐cluster config) illustrates exactly this approach, showing how to list each member with `_id` and `host` under `replicaSetConfigurationSettings.configuration.members`. ([medium.com][1])
* Bitnami’s own `values.yaml` for MongoDB (look for `replicaSetConfigurationSettings.enabled`) explains how the chart builds and runs the embedded JS snippet. ([raw.githubusercontent.com][2])

[1]: https://medium.com/%40biagio.tozzi/deployng-mongodb-across-multiple-kubernetes-clusters-with-submariner-network-using-helm-and-5eb6b08b3ba7?utm_source=chatgpt.com "Deploying MongoDB across multiple Kubernetes clusters with ..."
[2]: https://raw.githubusercontent.com/bitnami/charts/master/bitnami/mongodb/values.yaml?utm_source=chatgpt.com "https://raw.githubusercontent.com/bitnami/charts/m..."
