# RCDN KSR Rocket.Chat and MongoDB Deployment

## Architecture Overview

### Objective

* Goal:
  * Provide a high-availability, security aligned Rocket.Chat service that cuts RTO to <1h and supports horizontal scale for mission surges.
* Scope:
  * Migrate current deployment from VM based Rocket.Chat/MongoDB (RCMDB) to containerized deployment on a Tanzu Kubernetes Grid (TKG) cluster.
  * Introduce Harbor registry, Contour TLS ingress, NetApp Trident Container Storage Interface (CSI) & Protect, security and compliance policies, monitoring observability, and GitOps automation.
* Execution:
  * Phase 1: Migrate current deployments to TKG clusters than upgrade to latest versions to stay in support.
  * Phase 2: Deploy RCMDB on a globally stretched replica set with local failover.
  * Phase 3: Enable ‘island mode’ where each site will stay operational even during times of Denied, Degraded, Intermittent, or Limited (DDIL) WAN connection with consistency/sync upon reconnection.
  * This will include handling of shared Active Directory authentication, site-local PKI/DNS services, and failover/isolation contingencies.

### Phase 1: Migrate and Upgrade

* Migrating the current RCMDB VM based deployment is a straight-forward procedure that backs up the existing Mongo database in-place to a compressed file and copied to the TKG administrative workstation.
* On the TKG cluster, the same MongoDB version is installed and configured as a three-node replica set and the backup file is copied to the primary replica and the Rocket.Chat database is restored in place.
* Upgrading Rocket.Chat and MongoDB is done by first upgrading Rocket.Chat to the latest version and then performing a double upgrade of MongoDB to the latest supported version.

### Phase 2: Globally Stretched Rocket.Chat Cluster

* Architecture
  * MongoDB Replica Set: Deploy MongoDB as a replica set with members in multiple sites.
  * Rocket.Chat Pods: Application pods run across all sites with 2-3 replicas in each. Use a global load balancing service to route users to any site. The pods use the shared MongoDB replica set as their database.
  * Load Balancing: Front end traffic via a global load balancer or DNS that directs users to a site. Contour Ingress in each site handles TLS termination for local requests. If a site is down, traffic is automatically served by the remaining sites.
  * Data Access: Since all Rocket.Chat pods talk to the shared MongoDB cluster, any pod in any site can write data. MongoDB’s failover is automatic: if the primary’s site goes down, the next member (in another site) becomes primary. For sustained writes, network latency between sites must be low enough (<100 ms) to avoid impacting MongoDB election times.
* Reliability and Failover
  * Maximizes availability if inter-site links remain up. In practice, use at least three sites or an arbiter node to avoid that scenario.
  * Failure in one datacenter simply causes MongoDB failover
  * Clients connected to the surviving sites see no downtime.
  * Restoration of the downed site causes it to rejoin the cluster and replicate missed writes.
  * Offers near-seamless failover (near-zero RTO) when networks are healthy.
* DNS and PKI
  * DNS can present a single hostname that resolves to all site ingresses (via DNS or GSLB).
  * Each site’s DNS and Contour use certificates from the same CA hierarchy
  * Clients trust any site’s endpoint.
  * In isolation, if local DNS and CA are working, certificates do not need renewal. If the WAN link is cut, site DNS should still resolve local service names from its cache or local zone.
* Pros and Cons
  * Pros
    * Automatic cross-site failover
    * A single consistent dataset; no need for manual resync
    * Active users see few disruptions if designed with ≥3-site quorum
  * Cons
    * Requires low-latency, high-bandwidth links and reliable WAN
    * Data path spans DCs, so network issues can cause latency
    * MongoDB writes may become read-only if the majority site fails
    * Operational complexity in deploying a multi-site K8s cluster or federated cluster

### Phase 3: Independent Per-Site Clusters Island Mode

* Architecture
  * Local MongoDB Replica Sets: Each site, deploy a MongoDB replica set (typically 3 nodes within the site, or fewer if resource-constrained).
  * Local Rocket.Chat: Run Rocket.Chat in each site pointing to the local database. Rocket.Chat instances have identical configuration where possible (same version, same settings).
  * Network: Sites do not rely on cross-site networking for day-to-day operations. Clients connect to the local site’s ingress/DNS. A site-level Contour handles TLS independently for local traffic.
  * Active Directory/SSO: Even though clusters are isolated, they share the same AD IDP. Each site’s Rocket.Chat must be able to reach the AD servers (or RODCs) for user authentication.
  * DNS and PKI: Each site has its own DNS for local names. A global name (e.g. chat.example.com) could be a GeoDNS record split per site, or each site might use a site-specific name (e.g. chat-A, chat-B). Each site’s TLS certificate is issued by the shared CA hierarchy but managed locally. In isolation, certs continue to work because trust anchors exist at each site.

* Synchronization Strategy (User Data, Messages, Config)
  * After sites reconnect, they need to sync user accounts, channels, and messages. Rocket.Chat does not natively support multi-master sync, so this is a challenge. Possible approaches include:
  * Rocket.Chat Federation: Sites can automatically exchange direct messages and channels.
  * Custom Sync Process: Scripts or use data exports to merge differences. In practice, it may be simplest to restrict collaboration: allow users only in their local site to chat when isolated and only sync non-conflicting data (e.g. new users and new messages) after rejoin.
  * Data Partitioning: To ease sync, you could logically partition work by site (e.g. “site-A” channels and “site-B” channels). After reconnection, only cross-site communication (like federated DM) needs syncing.
  * Synchronization is the most complex part of model 2. It trades off complexity for full isolation.
* Reliability and Failover
  * Excels in isolation resilience: each site can continue full operations if it loses connection to others.
  * No site depends on WAN for reads/writes, so RTO is effectively zero per site. If a site completely fails, it has no effect on others (until sync time).
  * If sites diverge and then reconnect, resolving conflicts may be time-consuming.
  * There is no automatic failover of user connections across sites
  * Operationally, this model is simpler per-site (each cluster is self-contained) but introduces manual steps for federation and eventual consistency.
* DNS and PKI
  * Each site uses its own DNS name and certificate (though signed by the shared CA).
  * Global DNS need not span sites except perhaps for public names.
  * Site-local DNS continues serving names in isolation.
  * If certificates expire while isolated, each site must renew via its local CA (since WAN is down).
  * The shared root CA means certificates from one site are still trusted by others when rejoining (all have the same root).
* Pros and Cons
  * Pros
    * Maximum independence and resilience to WAN outages.
    * Sites stay fully operational if disconnected.
    * Local performance is best (database is local).
    * Simplifies scaling (each site scales itself).
  * Cons
    * No seamless failover.
    * Reconciling data afterwards is complex.
    * Admin overhead to sync accounts/channels.
    * Potential for data conflict and duplicate content.
    * Less ideal if users expect global presence.
