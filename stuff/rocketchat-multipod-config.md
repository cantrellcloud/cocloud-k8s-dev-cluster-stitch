The issue you're experiencing, where Rocket.Chat becomes unreachable ("Connecting..." message looping) when scaling beyond a single replica, is typically due to one or more of the following common problems:

### 1. **Session Persistence and Load Balancing**

Rocket.Chat requires WebSocket support and session persistence. If these aren't correctly configured, especially with multiple pods, it results in continuous reconnects.

**Fix:**

* Ensure your ingress (Contour or another ingress controller) properly supports WebSocket connections.
* Enable WebSocket support explicitly in your ingress controller configuration.

For **Contour**, your ingress configuration should explicitly allow WebSockets and handle persistent sessions correctly. Here's an optimized example for your ingress (`HTTPProxy`) setup:

```yaml
apiVersion: projectcontour.io/v1
kind: HTTPProxy
metadata:
  name: rocketchat-proxy
  namespace: rocketchat
spec:
  virtualhost:
    fqdn: rocket.dev.local
    tls:
      secretName: rocket-tls
  routes:
    - services:
        - name: rocketchat
          port: 3000
      enableWebsockets: true  # <--- explicitly enable WebSockets
```

### 2. **Rocket.Chat Environmental Variables for Replicas**

When running multiple Rocket.Chat pods, Rocket.Chat must know about all its instances to manage presence, notifications, and message broadcasting correctly.

**Fix:**
Ensure you have configured the following environmental variables explicitly in your Rocket.Chat Helm `values.yaml` to support multiple replicas:

```yaml
replicaCount: 3

rocketchat:
  extraEnv:
    - name: INSTANCE_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: OVERWRITE_SETTING_Show_Setup_Wizard
      value: "completed"
    - name: OVERWRITE_SETTING_Site_Url
      value: "https://rocket.dev.local"
```

* `INSTANCE_IP` helps Rocket.Chat pods identify themselves.
* `OVERWRITE_SETTING_Site_Url` ensures the URL is consistently used across pods.

### 3. **MongoDB Oplog Configuration**

Rocket.Chat requires a properly configured MongoDB oplog when running multiple replicas.

Check your connection strings to MongoDB explicitly in your Rocket.Chat deployment:

```yaml
externalMongodbUrl: "mongodb://rktservice:<password>@rocketchat-svc.mongodb.svc.cluster.local/rocketchat-db?authSource=admin&replicaSet=rs0"
externalMongodbOplogUrl: "mongodb://rktservice:<password>@rocketchat-svc.mongodb.svc.cluster.local/local?authSource=admin&replicaSet=rs0"
```

* Ensure that the `replicaSet` parameter is correctly defined and that your MongoDB is configured as a replica set.

### 4. **Sticky Sessions and Load Balancer Configuration**

Rocket.Chat sessions require persistent ("sticky") sessions at the ingress/load balancer level.

If you use Envoy/Contour ingress, sticky sessions are implicitly supported, but you must explicitly enable them if you use another load balancer.

For Envoy (Contour):

* WebSocket support is enabled by default with `enableWebsockets`.
* If still facing session issues, ensure your ingress/load balancer supports session persistence.

If using an external load balancer (like MetalLB or an external LB device), explicitly configure sticky sessions (often by client IP or cookie).

### Recommended Complete Rocket.Chat Ingress Configuration (Contour):

Here's a complete recommended setup based on your existing files and infrastructure:

```yaml
apiVersion: projectcontour.io/v1
kind: HTTPProxy
metadata:
  name: rocketchat-proxy
  namespace: rocketchat
spec:
  virtualhost:
    fqdn: rocket.dev.local
    tls:
      secretName: rocket-tls
  routes:
    - services:
        - name: rocketchat-rocketchat
          port: 80  # Match your service port defined in RocketChat helm chart
      enableWebsockets: true
      loadBalancerPolicy:
        strategy: Cookie  # explicitly set session persistence using cookies
```

### Validation Steps:

1. Apply your updated ingress configuration:

```bash
kubectl apply -f ingress-rocketchat.yaml
```

2. Scale up Rocket.Chat pods to test:

```bash
kubectl scale deployment rocketchat-rocketchat --replicas=3 -n rocketchat
```

3. Verify the pods are correctly running and ready:

```bash
kubectl get pods -n rocketchat -o wide
```

4. Check logs to ensure pods correctly handle connections:

```bash
kubectl logs deployment/rocketchat-rocketchat -n rocketchat
```

### Final Recommendation:

* **Explicitly enable WebSocket and sticky sessions** via ingress configuration.
* **Correctly set environmental variables and MongoDB replica set parameters** for your Rocket.Chat deployment.

Applying these adjustments should resolve the repeated "Connecting..." issue when scaling Rocket.Chat beyond a single pod.
