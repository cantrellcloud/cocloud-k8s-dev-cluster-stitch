# CUI

## SDD-RocketChat-MongoDB-K8s-Enterprise (Air-Gapped)

Author: Ron Cantrell
Date: 15 May 2025

1. A globally stretched Rocket.Chat and MongoDB replica set cluster with local failover.
2. Independent Rocket.Chat instances per site with eventual consistency/sync, supporting isolated 'island mode'.

This will include handling of shared Active Directory authentication, site-local PKI/DNS services, and failover/isolation contingencies.

## Multi-Site (N+1) Deployment for Rocket.Chat on Tanzu Kubernetes Grid

To support operation across N+1 datacenters, we consider two complementary models: **(1) a globally stretched cluster** where Rocket.Chat and its MongoDB replica set span multiple sites for seamless failover, and **(2) independent per-site “island-mode” clusters** where each site runs its own Rocket.Chat instance and MongoDB set, with eventual synchronization of data across sites. Both designs share certain services (e.g. a common AD identity provider) but differ in data locality and failover behavior. The following sections detail each model’s architecture, components, and operational considerations.

### Common Infrastructure: Identity, DNS, and PKI

A shared Active Directory (AD) forest must provide SSO across all sites. In practice, deploy domain controllers (DCs) in each site – ideally writable DCs or Read-Only Domain Controllers (RODCs) in remote sites – so users can authenticate locally even if WAN links fail.  RODCs allow caching of user credentials and improve security in branch offices.  For Rocket.Chat, configure LDAP or SAML SSO against AD/ADFS so that users in any site authenticate against the same identity store.

Each site should run a **local DNS server** holding the site’s internal zones and forwarding global queries as needed.  Use split-horizon or geo-DNS so users reach the local Rocket.Chat endpoint.  If global names (e.g. chat.example.com) are used, consider geo- or multi-site load balancing (GSLB) to direct users to the nearest site.  During extended isolation, the local DNS server must still resolve site services; ensure DNS caches are primed and that the local DNS is authoritative for its subset of zones.

For **PKI and TLS**, use a hierarchical design: a central offline root CA and per-site subordinate CAs (or an AD Certificate Services issuing CA) that issue site certificates.  Distribute the root and intermediate CA certificates to all sites so each site trusts the others’ certificates.  In isolation, each site’s CA can still issue new certs signed by its intermediate; ensure long lifetimes or manual out-of-band renewal if the root is unreachable.  Configure Contour Ingress to use Kubernetes `tls` secrets containing the server certificate and key (with any needed SANs).  (Certificate renewal can be automated if the CA is reachable, or done manually during long outages.)

In summary, ensure **shared AD/SSO** (global forest with local DCs/RODCs), **site-local DNS/CA**, and **trusted cross-site CA hierarchy**.  This lets any Rocket.Chat cluster (stretched or local) use the same user accounts and TLS trust anchors in all sites.

## Model 1: Globally Stretched Rocket.Chat + MongoDB Cluster

In the first model, Rocket.Chat and MongoDB run as a single, multi-site Kubernetes cluster (or closely peered clusters) such that both chat servers and the MongoDB replica set have members in every datacenter. A single logical workload spans sites and failover is automatic.

### Model 1 Architecture

* **MongoDB Replica Set**: Deploy MongoDB as a replica set with members in multiple sites. For example, with three sites (A, B, C), run one MongoDB pod (with local persistent volume) in each site.  This yields a 3-node set; the primary can reside in any site, and if that site fails, a new primary is elected among remaining nodes.  (If only two sites are available, use an odd number of nodes by placing 2 nodes in one site and 1 in the other, but this can force read-only mode if the majority site fails.)  MongoDB’s official guidance is to spread nodes so that no single-site loss deprives the set of a majority.

* **Rocket.Chat Pods**: Run Rocket.Chat application pods across sites (for example, 2-3 replicas in each). Use a global service or ingress that can route users to any site. The pods use the shared MongoDB replica set as their database (point all to the same replica set URI).

* **Load Balancing**: Front end traffic via a global load balancer or DNS that directs users to a site. Contour Ingress in each site handles TLS termination for local requests. If a site is down, traffic is automatically served by the remaining sites.

* **Data Access**: Since all Rocket.Chat pods talk to the shared MongoDB cluster, any pod in any site can write data. MongoDB’s failover is automatic: if the primary’s site goes down, the next member (in another site) becomes primary. For sustained writes, network latency between sites must be low enough (<100 ms) to avoid impacting MongoDB election times.

### Model 1 Reliability and Failover

This model maximizes availability **if inter-site links remain up**. With an odd number of nodes (e.g. 3 across 3 sites), losing any one site still leaves a majority for writes. In the two-site case, plan node placement carefully (e.g. 2 nodes in Site A, 1 in Site B): if Site B (minority) fails, Site A can still write, but if Site A (majority) fails, Site B alone cannot elect a primary. In practice, use at least three sites or an arbiter node to avoid that scenario.

Failure in one datacenter simply causes MongoDB failover; Rocket.Chat pods in the failed site lose connectivity to the database and crash, but pods in other sites keep running and serving clients. Clients connected to the surviving sites see no downtime. Restoration of the downed site causes it to rejoin the cluster and replicate missed writes. (If the partition persists with a site isolated but clients still hitting it, those pods become read-only or error out.) In short, model 1 offers **near-seamless failover** (near-zero RTO) when networks are healthy.

### Model 1 DNS and PKI

Under model 1, because it is one logical cluster, DNS can present a single hostname (chat.example.com) that resolves to all site ingresses (via DNS or GSLB). Each site’s DNS and Contour use certificates from the same CA hierarchy so that clients trust any site’s endpoint.  In isolation, as long as local DNS and CA are working, certificates do not need renewal. If the WAN link is cut, site DNS should still resolve local service names from its cache or local zone.

### Model 1 Helm Deployment, Storage, and TLS

Use the official Rocket.Chat Helm chart (e.g. from `rocketchat/helm-charts`) configured with a MongoDB replica set URI covering all nodes. For example, in values.yaml specify replica counts and enable replica set features.  Deploy NetApp Trident CSI and create a StorageClass for your ONTAP volumes so that each Mongo pod gets a persistent volume.  Each site’s storage can be independent (using local ONTAP arrays) but consider NetApp’s MetroCluster or SnapMirror if wanting synchronous storage replication (though MongoDB handles data replication at the database level, so cross-site volume sync is optional).

Enable **Trident Protect** to back up volumes: schedule application-consistent snapshots of the Mongo data and Rocket.Chat attachments. These snapshots allow point-in-time recovery of a site’s data if needed. For example, if a site suffers catastrophic failure, you could restore its volumes from Trident Protect backups to new hardware.

Configure Contour Ingress with TLS secrets in each site namespace. Create a Kubernetes `Secret` of type `kubernetes.io/tls` containing the site certificate and key (with any intermediate certs). Optionally use cert-manager integrated with the site CA to automate certificate renewal; ensure ACME or CA access is possible from each site.

### Model 1 Pros and Cons

* **Pros:** Automatic cross-site failover; a single consistent dataset; no need for manual resync. Active users see few disruptions if designed with ≥3-site quorum.
* **Cons:** Requires low-latency, high-bandwidth links and reliable WAN. The data path spans DCs, so network issues can cause latency. MongoDB writes may become read-only if the majority site fails. Operational complexity in deploying a multi-site K8s cluster or federated cluster.

In summary, Model 1 is more “**reliable-under-connectivity**” – if WAN is intact, it provides near-continuous operation with automatic failover and one unified dataset.

## Model 2: Independent Per-Site Clusters (“Island Mode”)

In the second model, each site runs its own Rocket.Chat deployment and its own local MongoDB replica set, fully isolated from other sites during normal operation. Sites operate in **island mode** when disconnected, and data is later synchronized between sites after reconnection. This provides maximum local independence but complicates cross-site consistency.

&#x20;*Figure: Server racks and cabling in a site (illustrative).*

### Model 2 Architecture

* **Local MongoDB Replica Sets:** In each site, deploy a MongoDB replica set (typically 3 nodes within the site, or fewer if resource-constrained). This set is not directly connected to other sites. Each site’s Rocket.Chat pods use their local Mongo set for reads/writes.

* **Local Rocket.Chat:** Run Rocket.Chat in each site (via Helm) pointing to the local database. Rocket.Chat instances have identical configuration where possible (same version, same settings).

* **Network:** Sites do not rely on cross-site networking for day-to-day operations. Clients connect to the local site’s ingress/DNS. A site-level Contour handles TLS independently for local traffic.

* **Active Directory/SSO:** Even though clusters are isolated, they share the same AD IDP. Each site’s Rocket.Chat must be able to reach the AD servers (or RODCs) for user authentication. If AD replication is fully multi-master, users created at any site appear everywhere, but if not, coordinate user provisioning. AD FS or LDAP proxies might be set up per site.

* **DNS and PKI:** Each site has its own DNS for local names. A global name (e.g. chat.example.com) could be a GeoDNS record split per site, or each site might use a site-specific name (e.g. chat-A, chat-B). Each site’s TLS certificate is issued by the shared CA hierarchy but managed locally. In isolation, certs continue to work because trust anchors exist at each site.

### Model 2 Synchronization Strategy (User Data, Messages, Config)

After sites reconnect, they need to **sync user accounts, channels, and messages**. Rocket.Chat does not natively support multi-master sync, so this is a challenge. Possible approaches include:

* **Rocket.Chat Federation:** Newer versions support a “federation” mode using the Matrix protocol, allowing servers to share messages across instances. If enabled, sites can automatically exchange direct messages and channels. However, federation support may not be fully mature for all features, and it’s complex to set up for on-prem.

* **Custom Sync Process:** More commonly, one might write scripts or use data exports to merge differences. For example, after a partition, run a scheduled job that exports new users and messages from each site and imports them to the others. This could use MongoDB tools (mongodump/restore of oplogs) or Rocket.Chat’s REST API to pull recent data. This approach requires conflict resolution: if the same channel or user was modified in two sites, decide which change “wins”. In practice, it may be simplest to restrict collaboration: allow users only in their local site to chat when isolated, and only sync non-conflicting data (e.g. new users and new messages) after rejoin.

* **Data Partitioning:** To ease sync, you could logically partition work by site (e.g. “site-A” channels and “site-B” channels). After reconnection, only cross-site communication (like federated DM) needs syncing.

* **Delayed Mongo Sync:** In some designs, one might take backups and roll forward one database using another’s oplog, but this is error-prone.

In short, **synchronization is the most complex part of model 2**. It trades off complexity for full isolation.

### Model 2 Reliability and Failover

Model 2 excels in **isolation resilience**: each site can continue full operations if it loses connection to others. No site depends on WAN for reads/writes, so RTO is effectively zero per site. If a site completely fails, it has no effect on others (until sync time). However, if sites diverge and then reconnect, resolving conflicts may be time-consuming.

There is no automatic failover of user connections across sites; a user from Site A who tries to use Site B’s chat while Site A is down would either be unable to login (if accounts not synced) or appear as a different user.  Operationally, this model is simpler per-site (each cluster is self-contained) but introduces manual steps for federation and eventual consistency.

### Model 2 DNS and PKI

DNS and PKI are simpler: each site’s Rocket.Chat uses its own DNS name and certificate (though signed by the shared CA). Global DNS need not span sites except perhaps for public names. Site-local DNS continues serving names in isolation. If certificates expire while isolated, each site must renew via its local CA (since WAN is down). The shared root CA means certificates from one site are still trusted by others when rejoining (all have the same root).

### Model 2 Helm Deployment, Storage, and TLS

Deploy Rocket.Chat separately in each cluster using the same Helm chart, but with values adjusted for the local Mongo set. Use Trident StorageClass for persistent volumes at each site. Each Mongo replicaset uses its own PVCs backed by NetApp volumes; there is no cross-site storage sync at the block level.

Use Trident Protect at each site to snapshot local volumes. In the event a site is lost, its state can be recovered independently. These local snapshots do not cross sites by default, but one could manually copy backups between sites if needed (e.g. restore site A’s latest backup into site B’s database after a failure).

Contour Ingress in each site uses its own TLS secret for the local domain. For example, create a secret containing the cert for `chat.siteA.example.com` and attach it to the HTTPProxy for Site A. Cert-manager can automate this if it has an issuing CA reachable, or operators can generate CSR and renew manually.

### Model 2 Pros and Cons

* **Pros:** Maximum independence and resilience to WAN outages. Sites stay fully operational if disconnected. Local performance is best (database is local). Simplifies scaling (each site scales itself).
* **Cons:** No seamless failover; reconciling data afterwards is complex. Admin overhead to sync accounts/channels. Potential for data conflict and duplicate content. Less ideal if users expect global presence.

Model 2 is more “**reliable-under-isolation**”: even if networks fail completely, each site’s Chat stays up (albeit partitioned). However, it requires good processes for post-isolation synchronization.

## Comparison and Guidance

| Aspect                  | Model 1: Stretched (Active-Active)                                      | Model 2: Independent Islands                                                                            |
| ----------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| **Data Consistency**    | Single global dataset; immediate consistency                            | Eventually consistent; separate datasets                                                                |
| **Failover**            | Automatic via MongoDB elections                                         | Manual; no automatic cross-site takeovers                                                               |
| **Isolation Tolerance** | Limited by DB quorum (can become read-only if majority site lost)       | Full site autonomy; no cross-site dependency                                                            |
| **Network Dependency**  | Requires reliable low-latency WAN                                       | Only for sync; day-to-day can be offline                                                                |
| **Complexity**          | Complex K8s deployment and networking                                   | Complex sync logic and conflict handling                                                                |
| **RTO/RPO**             | Very low (if WAN OK); RPO is zero (data is real-time)                   | Zero RTO per site, but multi-site RPO is data since last sync                                           |
| **Use Case**            | When continuous global collaboration is critical and links are reliable | When sites must operate independently (e.g. military or remote bases), and post-hoc merge is acceptable |

In general, **Model 1** is more reliable *when inter-site connectivity is strong* – it keeps all users on a single “plane” of data, and failover is near-instant. It demands careful quorum planning (e.g. three-site quorum). **Model 2** is safer when sites can lose connectivity for long periods: each site is self-sufficient, but you must accept that data will diverge and need merging. Choose the stretched model for the lowest downtime under normal conditions; choose island mode if you must guarantee local operations even under extreme isolation.

## (Appendix) Summary of Implementation Stack

* **Helm Deployment:** Use Rocket.Chat’s official Helm chart repository. Provide site-specific values: Mongo replica URIs (for Model 1 a multi-site URI, for Model 2 just local hosts), ingress hostnames, and any cloud-init scripts.
* **Storage:** Install NetApp Trident CSI. Define StorageClass (e.g. using ONTAP NFS/iSCSI). Rocket.Chat and Mongo each use PersistentVolumeClaims. For Model 1, volumes can remain site-local; Mongo handles replication.
* **Local DR:** Install Trident Protect in each cluster (per site). Protect creates scheduled snapshots/backups of the Rocket.Chat and Mongo PVCs. Use `tridentctl protect schedule` to automate backups. In a disaster, use `tridentctl restore` to recover volumes.
* **TLS via Contour:** Deploy Contour/Envoy in each cluster. Create HTTPProxy resources for Rocket.Chat, attaching Kubernetes `Secret`s of type `tls` with certs. Contour requires each secret to have `tls.crt` and `tls.key`. For both models, ensure SANs cover any multi-site DNS names or use a wildcard. Consider enabling Contour’s TLS delegation if sharing secrets across namespaces is needed.
