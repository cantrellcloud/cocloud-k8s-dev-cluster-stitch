Below is a **Mermaid flow-chart** that walks through a practical test plan for both fail-over and full disaster-recovery (DR) scenarios described in the Enterprise Rocket Chat / MongoDB multi-site design.
Copy the code block into any Markdown viewer that supports Mermaid to render the diagram.

```mermaid
flowchart TD
  %% ---------- PREP ----------
  A([Start<br/>Test Plan])

  subgraph Prep["Preparation"]
    direction TB
    B1([Baseline health checks:<br/>• Mongo rs.status()<br/>• Rocket Chat /healthz<br/>• Snapshot current metrics])
  end
  A --> B1

  %% ---------- MODEL 1 (Stretch) ----------
  subgraph M1["Model 1 – Globally-Stretched Cluster<br/>(active-active)"]
    direction TB
    C1([Fail-over test<br/>“Pull the plug” on Site A<br/>• Power-off K8s nodes<br/>• Block Site-A links])
    C2([Observe automatic election:<br/>MongoDB primary moves to Site B;<br/>Rocket Chat pods re-connect])
    C3([Functional validation:<br/>• Login + post message<br/>• Check latency & logs])
    C4([Recover Site A → power-on;<br/>verify SECONDARY state & resync])
  end
  B1 --> C1 --> C2 --> C3 --> C4

  %% ---------- MODEL 2 (ISLAND) ----------
  subgraph M2["Model 2 – Independent “Island” Clusters"]
    direction TB
    D1([Isolation test<br/>Cut WAN/GSLB between sites])
    D2([Each site runs locally:<br/>• Users auth via local DC/RODC<br/>• New msgs/users created])
    D3([Reconnect WAN])
    D4([Run sync / federation job;<br/>resolve conflicts & verify global view])
  end
  C4 --> D1 --> D2 --> D3 --> D4

  %% ---------- DISASTER-RECOVERY ----------
  subgraph DR["Disaster Recovery with Trident Protect"]
    direction TB
    E1([Take scheduled snapshot & SnapMirror<br/>to remote DR vault])
    E2([Simulate total loss of Site A<br/>(delete PVs + K8s objects)])
    E3([Restore volumes & manifests at DR site<br/>using tridentctl restore])
    E4([Redeploy Rocket Chat → point to restored MongoDB])
    E5([Validation:<br/>• Data integrity (messages, files)<br/>• User login/session<br/>• Metrics OK])
  end
  D4 --> E1 --> E2 --> E3 --> E4 --> E5

  E5 --> F([End<br/>Test Plan])

  %% ---------- STYLES ----------
  classDef prep fill:#D5E8D4,stroke:#4C8045;
  classDef m1 fill:#FFF2CC,stroke:#B58C00;
  classDef m2 fill:#DDEBF7,stroke:#2E73B3;
  classDef dr fill:#F8CECC,stroke:#B85450;
  class Prep prep
  class M1 m1
  class M2 m2
  class DR dr
```

**How to use the diagram**

1. **Baseline** – confirm the cluster is healthy before you break anything.
2. **Model 1 tests** – simulate a data-center outage and watch the stretched replica-set elect a new primary while Rocket Chat keeps serving traffic.
3. **Model 2 tests** – cut the WAN to prove each site can run autonomously (“island mode”) and then reconcile data after reconnection.
4. **DR tests** – prove that a Trident Protect snapshot plus SnapMirror copy can be restored in a new cluster, with Rocket Chat functioning on the recovered dataset.

The steps map directly to the fail-over and DR mechanisms laid out in the system-design document for the enterprise, air-gapped Rocket Chat deployment with NetApp Trident and Tanzu Kubernetes Grid.
Below is a **Mermaid flow-chart** that walks through a practical test plan for both fail-over and full disaster-recovery (DR) scenarios described in the Enterprise Rocket Chat / MongoDB multi-site design.
Copy the code block into any Markdown viewer that supports Mermaid to render the diagram.

```mermaid
flowchart TD
  %% ---------- PREP ----------
  A([Start<br/>Test Plan])

  subgraph Prep["Preparation"]
    direction TB
    B1([Baseline health checks:<br/>• Mongo rs.status()<br/>• Rocket Chat /healthz<br/>• Snapshot current metrics])
  end
  A --> B1

  %% ---------- MODEL 1 (Stretch) ----------
  subgraph M1["Model 1 – Globally-Stretched Cluster<br/>(active-active)"]
    direction TB
    C1([Fail-over test<br/>“Pull the plug” on Site A<br/>• Power-off K8s nodes<br/>• Block Site-A links])
    C2([Observe automatic election:<br/>MongoDB primary moves to Site B;<br/>Rocket Chat pods re-connect])
    C3([Functional validation:<br/>• Login + post message<br/>• Check latency & logs])
    C4([Recover Site A → power-on;<br/>verify SECONDARY state & resync])
  end
  B1 --> C1 --> C2 --> C3 --> C4

  %% ---------- MODEL 2 (ISLAND) ----------
  subgraph M2["Model 2 – Independent “Island” Clusters"]
    direction TB
    D1([Isolation test<br/>Cut WAN/GSLB between sites])
    D2([Each site runs locally:<br/>• Users auth via local DC/RODC<br/>• New msgs/users created])
    D3([Reconnect WAN])
    D4([Run sync / federation job;<br/>resolve conflicts & verify global view])
  end
  C4 --> D1 --> D2 --> D3 --> D4

  %% ---------- DISASTER-RECOVERY ----------
  subgraph DR["Disaster Recovery with Trident Protect"]
    direction TB
    E1([Take scheduled snapshot & SnapMirror<br/>to remote DR vault])
    E2([Simulate total loss of Site A<br/>(delete PVs + K8s objects)])
    E3([Restore volumes & manifests at DR site<br/>using tridentctl restore])
    E4([Redeploy Rocket Chat → point to restored MongoDB])
    E5([Validation:<br/>• Data integrity (messages, files)<br/>• User login/session<br/>• Metrics OK])
  end
  D4 --> E1 --> E2 --> E3 --> E4 --> E5

  E5 --> F([End<br/>Test Plan])

  %% ---------- STYLES ----------
  classDef prep fill:#D5E8D4,stroke:#4C8045;
  classDef m1 fill:#FFF2CC,stroke:#B58C00;
  classDef m2 fill:#DDEBF7,stroke:#2E73B3;
  classDef dr fill:#F8CECC,stroke:#B85450;
  class Prep prep
  class M1 m1
  class M2 m2
  class DR dr
```

**How to use the diagram**

1. **Baseline** – confirm the cluster is healthy before you break anything.
2. **Model 1 tests** – simulate a data-center outage and watch the stretched replica-set elect a new primary while Rocket Chat keeps serving traffic.
3. **Model 2 tests** – cut the WAN to prove each site can run autonomously (“island mode”) and then reconcile data after reconnection.
4. **DR tests** – prove that a Trident Protect snapshot plus SnapMirror copy can be restored in a new cluster, with Rocket Chat functioning on the recovered dataset.

The steps map directly to the fail-over and DR mechanisms laid out in the system-design document for the enterprise, air-gapped Rocket Chat deployment with NetApp Trident and Tanzu Kubernetes Grid.
Below is a **Mermaid flow-chart** that walks through a practical test plan for both fail-over and full disaster-recovery (DR) scenarios described in the Enterprise Rocket Chat / MongoDB multi-site design.
Copy the code block into any Markdown viewer that supports Mermaid to render the diagram.

```mermaid
flowchart TD
  %% ---------- PREP ----------
  A([Start<br/>Test Plan])

  subgraph Prep["Preparation"]
    direction TB
    B1([Baseline health checks:<br/>• Mongo rs.status()<br/>• Rocket Chat /healthz<br/>• Snapshot current metrics])
  end
  A --> B1

  %% ---------- MODEL 1 (Stretch) ----------
  subgraph M1["Model 1 – Globally-Stretched Cluster<br/>(active-active)"]
    direction TB
    C1([Fail-over test<br/>“Pull the plug” on Site A<br/>• Power-off K8s nodes<br/>• Block Site-A links])
    C2([Observe automatic election:<br/>MongoDB primary moves to Site B;<br/>Rocket Chat pods re-connect])
    C3([Functional validation:<br/>• Login + post message<br/>• Check latency & logs])
    C4([Recover Site A → power-on;<br/>verify SECONDARY state & resync])
  end
  B1 --> C1 --> C2 --> C3 --> C4

  %% ---------- MODEL 2 (ISLAND) ----------
  subgraph M2["Model 2 – Independent “Island” Clusters"]
    direction TB
    D1([Isolation test<br/>Cut WAN/GSLB between sites])
    D2([Each site runs locally:<br/>• Users auth via local DC/RODC<br/>• New msgs/users created])
    D3([Reconnect WAN])
    D4([Run sync / federation job;<br/>resolve conflicts & verify global view])
  end
  C4 --> D1 --> D2 --> D3 --> D4

  %% ---------- DISASTER-RECOVERY ----------
  subgraph DR["Disaster Recovery with Trident Protect"]
    direction TB
    E1([Take scheduled snapshot & SnapMirror<br/>to remote DR vault])
    E2([Simulate total loss of Site A<br/>(delete PVs + K8s objects)])
    E3([Restore volumes & manifests at DR site<br/>using tridentctl restore])
    E4([Redeploy Rocket Chat → point to restored MongoDB])
    E5([Validation:<br/>• Data integrity (messages, files)<br/>• User login/session<br/>• Metrics OK])
  end
  D4 --> E1 --> E2 --> E3 --> E4 --> E5

  E5 --> F([End<br/>Test Plan])

  %% ---------- STYLES ----------
  classDef prep fill:#D5E8D4,stroke:#4C8045;
  classDef m1 fill:#FFF2CC,stroke:#B58C00;
  classDef m2 fill:#DDEBF7,stroke:#2E73B3;
  classDef dr fill:#F8CECC,stroke:#B85450;
  class Prep prep
  class M1 m1
  class M2 m2
  class DR dr
```

**How to use the diagram**

1. **Baseline** – confirm the cluster is healthy before you break anything.
2. **Model 1 tests** – simulate a data-center outage and watch the stretched replica-set elect a new primary while Rocket Chat keeps serving traffic.
3. **Model 2 tests** – cut the WAN to prove each site can run autonomously (“island mode”) and then reconcile data after reconnection.
4. **DR tests** – prove that a Trident Protect snapshot plus SnapMirror copy can be restored in a new cluster, with Rocket Chat functioning on the recovered dataset.

The steps map directly to the fail-over and DR mechanisms laid out in the system-design document for the enterprise, air-gapped Rocket Chat deployment with NetApp Trident and Tanzu Kubernetes Grid.

