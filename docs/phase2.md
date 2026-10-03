# Phase 2 — GitOps Setup

## CloudNativePG

```
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update

helm upgrade --install cnpg cnpg/cloudnative-pg \
  --namespace cnpg-system \
  --create-namespace \
  --wait \
  --timeout 15m



⎈ in minikube (default) minikube-fullstack on  feat/trial [!?] took 18s 
❯ kubectl get pods -n cnpg-system
NAME                                   READY   STATUS    RESTARTS   AGE
cnpg-cloudnative-pg-7b5f5d7b65-sfphx   1/1     Running   0          83s

⎈ in minikube (default) minikube-fullstack on  feat/trial [!?] 
❯ kubectl get crd | grep postgresql.cnpg.io
backups.postgresql.cnpg.io                     Namespaced   v1(storage)            2026-10-03T08:14:23Z
clusterimagecatalogs.postgresql.cnpg.io        Cluster      v1(storage)            2026-10-03T08:14:23Z
clusters.postgresql.cnpg.io                    Namespaced   v1(storage)            2026-10-03T08:14:23Z
databaseroles.postgresql.cnpg.io               Namespaced   v1(storage)            2026-10-03T08:14:23Z
databases.postgresql.cnpg.io                   Namespaced   v1(storage)            2026-10-03T08:14:23Z
failoverquorums.postgresql.cnpg.io             Namespaced   v1(storage)            2026-10-03T08:14:23Z
imagecatalogs.postgresql.cnpg.io               Namespaced   v1(storage)            2026-10-03T08:14:23Z
poolers.postgresql.cnpg.io                     Namespaced   v1(storage)            2026-10-03T08:14:23Z
publications.postgresql.cnpg.io                Namespaced   v1(storage)            2026-10-03T08:14:23Z
scheduledbackups.postgresql.cnpg.io            Namespaced   v1(storage)            2026-10-03T08:14:23Z
subscriptions.postgresql.cnpg.io               Namespaced   v1(storage)            2026-10-03T08:14:23Z
```

## Authentik

```
kubectl apply -k k8s/apps/authentik


⎈ in minikube (default) minikube-fullstack on  feat/trial [!?] 
❯ kubectl wait --for=condition=Ready cluster/authentik-postgres -n authentik --timeout=10m
cluster.postgresql.cnpg.io/authentik-postgres condition met

⎈ in minikube (default) minikube-fullstack on  feat/trial [!?] 
❯ kubectl rollout status deploy/authentik-server -n authentik --timeout=10m
deployment "authentik-server" successfully rolled out

⎈ in minikube (default) minikube-fullstack on  feat/trial [!?] 
❯ kubectl rollout status deploy/authentik-worker -n authentik --timeout=10m
deployment "authentik-worker" successfully rolled out

⎈ in minikube (default) minikube-fullstack on  feat/trial [!?] 
❯ kubectl get pods -n authentik -o wide
NAME                                READY   STATUS    RESTARTS   AGE     IP           NODE       NOMINATED NODE   READINESS GATES
authentik-postgres-1                1/1     Running   0          5m39s   10.0.0.221   minikube   <none>           <none>
authentik-server-7db56898d-hfvx2    1/1     Running   0          5m45s   10.0.0.52    minikube   <none>           <none>
authentik-worker-77b574578b-rqm7r   1/1     Running   0          5m45s   10.0.0.190   minikube   <none>           <none>

```

## Forgejo

```
❯ kubectl apply -k k8s/apps/forgejo
namespace/forgejo created
configmap/cloudsea-root-ca created
secret/forgejo-admin-secret created
secret/forgejo-secrets created
service/forgejo created
persistentvolumeclaim/forgejo-data created
deployment.apps/forgejo created
httproute.gateway.networking.k8s.io/forgejo created
tcproute.gateway.networking.k8s.io/forgejo-ssh created
cluster.postgresql.cnpg.io/forgejo-postgres created

⎈ in minikube (default) minikube-fullstack on  feat/trial [!?] 
❯ kubectl wait --for=condition=Ready cluster/forgejo-postgres -n forgejo --timeout=10m
cluster.postgresql.cnpg.io/forgejo-postgres condition met

⎈ in minikube (default) minikube-fullstack on  feat/trial [!?] 
❯ kubectl -n forgejo rollout status deploy/forgejo --timeout=10m
deployment "forgejo" successfully rolled out

```


## Garage 

> [!IMPORTANT]
> 
> Check if we really need this here
> 

Enable without OIDC

```
cat > /tmp/garage-ui-config-no-oidc.yaml <<'EOF'
server:
  host: "0.0.0.0"
  port: 8080
  environment: "production"
  domain: "garage.192.168.39.200.nip.io"
  root_url: "https://garage.192.168.39.200.nip.io"

garage:
  endpoint: "http://garage.garage.svc:3900"
  region: "garage"
  admin_endpoint: "http://garage.garage.svc:3903"
  admin_token: "d71afbc926da6762fb341b4ba9de8f7100d61e0f2f0eee98401a56ec955b6eae"

auth:
  admin:
    enabled: true
    username: "admin"
    password: "AdminGarage2026!"
  token:
    enabled: true
  oidc:
    enabled: false
EOF

kubectl -n garage create configmap garage-ui-config \
  --from-file=config.yaml=/tmp/garage-ui-config-no-oidc.yaml \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n garage rollout restart deploy/garage-ui
kubectl -n garage rollout status deploy/garage-ui --timeout=120s
kubectl -n garage logs -f deploy/garage-ui
```

**Reenable later **

```
kubectl apply -f k8s/apps/garage/webui.yaml
kubectl -n garage rollout restart deploy/garage-ui
kubectl -n garage rollout status deploy/garage-ui --timeout=120s
```
