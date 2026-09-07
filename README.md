# Fullstack K8s Platform Using Minikube

An enterprise-grade private cloud platform running locally on Minikube with Cilium eBPF, Gateway API, cert-manager, Argo CD, CloudNativePG, and Forgejo.

See [Plan](plan.md) for the roadmap and [Phase 1 Docs](docs/phase1.md) for initial cluster setup notes.

---

## 🏛 Platform Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                             Cilium Gateway API                              │
│              (L2 IP Pool: 192.168.39.200 - 192.168.39.219)                  │
└───────┬─────────────────────────────────────────────────────────────┬───────┘
        │                                                             │
        │ https://argocd.192.168.39.200.nip.io                        │ https://forgejo.192.168.39.201.nip.io
        ▼                                                             ▼
┌──────────────────┐                                          ┌──────────────────┐
│     Argo CD      │                                          │     Forgejo      │
│  (GitOps Engine) │                                          │  (Git & Actions) │
└───────┬──────────┘                                          └────────┬─────────┘
        │                                                              │
        │ Deploys & Manages                                            │ Uses DB
        ▼                                                              ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CloudNativePG Operator                              │
│                        (Namespace: cnpg-system)                             │
│                                                                             │
│  ┌─────────────────────────┐           ┌─────────────────────────────────┐  │
│  │ forgejo-postgres        │           │ authentik-postgres (upcoming)   │  │
│  │ (PostgreSQL 16 Cluster) │           │ (PostgreSQL 16 Cluster)         │  │
│  └─────────────────────────┘           └─────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📂 Repository Layout

```text
.
├── k8s/
│   ├── apps/
│   │   └── forgejo/                     # Forgejo application Kustomize package
│   │       ├── certificate.yaml         # cert-manager TLS certificate
│   │       ├── deployment.yaml          # Forgejo v10 Deployment with initContainer
│   │       ├── gateway.yaml             # Cilium Gateway & HTTPRoute (192.168.39.201)
│   │       ├── kustomization.yaml       # Kustomize entrypoint for Forgejo
│   │       ├── namespace.yaml           # forgejo namespace
│   │       ├── postgres.yaml            # CloudNativePG Cluster CR for Forgejo DB
│   │       ├── pvc.yaml                 # 10Gi data volume for Git storage
│   │       ├── secrets.yaml             # Initial admin credentials & secret key
│   │       └── service.yaml             # ClusterIP service (HTTP 3000 / SSH 2222)
│   ├── platform/
│   │   ├── cloudnative-pg/
│   │   │   └── application.yaml         # Argo CD Application for CloudNativePG Operator
│   │   ├── metrics-server/              # Cluster metrics
│   │   └── kustomization.yaml           # Platform Kustomize package
│   ├── argocd/
│   │   ├── argocd-gateway.yaml          # Gateway & HTTPRoute for Argo CD (192.168.39.200)
│   │   ├── ecrtificate.yaml             # Argo CD TLS certificate
│   │   └── values.yaml                  # Argo CD Helm values
│   ├── cloudsea-root-ca.crt             # Public Root CA certificate for TLS verification
│   ├── lb-ip-pool.yaml                  # Cilium LoadBalancer IP pool definition
│   ├── local-ca.yaml                    # cert-manager ClusterIssuer (cloudsea-local-ca)
│   ├── minikube-lbpool-announcement-policy.yaml # Cilium L2 Announcement policy
│   └── root-ca.yaml                     # Root CA certificate generator
├── docs/
│   └── phase1.md                        # Phase 1 documentation
├── 00-verify-minikube-cilium.sh         # Health check script for foundation
└── plan.md                              # Implementation roadmap
```

---

## 🚀 Quick Start Guide

### 1. Prerequisites & Cluster Foundation

1. **Start Minikube** with Cilium CNI (kube-proxy disabled):
   ```bash
   minikube start \
     --profile=k8s-platform \
     --driver=kvm2 \
     --container-runtime=containerd \
     --cpus=8 \
     --memory=32768 \
     --disk-size=200g \
     --extra-config=kubeadm.skip-phases=addon/kube-proxy
   ```

2. **Install Cilium & Gateway API**:
   ```bash
   # Install Gateway API CRDs
   kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml

   # Install Cilium with L2 announcements and Gateway API enabled
   helm install cilium cilium/cilium \
     --version 1.20.1 \
     --namespace kube-system \
     --set kubeProxyReplacement=true \
     --set l2announcements.enabled=true \
     --set gatewayAPI.enabled=true \
     --set hubble.enabled=true \
     --set hubble.relay.enabled=true \
     --set hubble.ui.enabled=true

   # Apply IP pool and announcement policy
   kubectl apply -f k8s/lb-ip-pool.yaml
   kubectl apply -f k8s/minikube-lbpool-announcement-policy.yaml
   ```

3. **Install cert-manager & Local CA**:
   ```bash
   helm repo add jetstack https://charts.jetstack.io && helm repo update
   helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true
   kubectl apply -f k8s/root-ca.yaml
   kubectl apply -f k8s/local-ca.yaml
   ```

---

### 2. Deploy Argo CD (GitOps Engine)

1. **Install Argo CD**:
   ```bash
   helm repo add argo https://argoproj.github.io/argo-helm && helm repo update
   helm install argocd argo/argo-cd -n argocd --create-namespace -f k8s/argocd/values.yaml
   kubectl apply -f k8s/argocd/ecrtificate.yaml
   kubectl apply -f k8s/argocd/argocd-gateway.yaml
   ```

2. **Access Argo CD**:
   * URL: `https://argocd.192.168.39.200.nip.io`
   * Username: `admin`
   * Password:
     ```bash
     kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
     ```

---

### 3. Deploy CloudNativePG Operator

The CloudNativePG operator manages PostgreSQL clusters across all namespaces.

Deploy via Argo CD:
```bash
kubectl apply -f k8s/platform/cloudnative-pg/application.yaml
```

Verify operator deployment:
```bash
kubectl get pods -n cnpg-system
```

---

### 4. Deploy Forgejo with Kustomize

Forgejo uses a dedicated PostgreSQL 16 cluster managed by CloudNativePG.

Deploy the complete Kustomize package:
```bash
kubectl apply -k k8s/apps/forgejo
```

What gets created:
* `Namespace`: `forgejo`
* `Cluster` (CNPG): `forgejo-postgres` (PostgreSQL 16 on standard PVC)
* `Deployment`: Forgejo v10.0.1 with auto-configured PostgreSQL connection and admin bootstrap
* `PVC`: 10Gi standard storage for Git repository data
* `Certificate`: TLS cert signed by `cloudsea-local-ca`
* `Gateway` & `HTTPRoute`: Exposed via Cilium Gateway at `forgejo.192.168.39.201.nip.io`

---

### 5. Access & Verify Forgejo

1. **Verify Pods and Database**:
   ```bash
   kubectl get pods,cluster -n forgejo
   ```

2. **Web UI & API Access**:
   * URL: `https://forgejo.192.168.39.201.nip.io`
   * Admin Username: `forgejoadmin`
   * Admin Password: `AdminForgejo2026!`

3. **Verify Git Operations with Local Root CA**:
   ```bash
   # Clone using the local Root CA certificate
   GIT_SSL_CAINFO=k8s/cloudsea-root-ca.crt \
   git clone https://forgejoadmin:AdminForgejo2026%21@forgejo.192.168.39.201.nip.io/forgejoadmin/gitops-test.git
   ```

---

## 🔄 Reusing CloudNativePG for Other Applications

Any application requiring a PostgreSQL database (e.g., Authentik, Harbor) can declare a `Cluster` custom resource in its namespace:

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: app-postgres
  namespace: <app-namespace>
spec:
  instances: 1
  imageName: ghcr.io/cloudnative-pg/postgresql:16.8
  primaryUpdateStrategy: unsupervised
  storage:
    size: 10Gi
    storageClass: standard
  bootstrap:
    initdb:
      database: app_db
      owner: app_user
```

CloudNativePG automatically creates `<cluster-name>-app` Secret with connection parameters (`host`, `port`, `user`, `password`, `dbname`, `uri`).

---

## 📋 Service Endpoints Summary

| Service | Namespace | Hostname / URL | IP | Credentials |
| :--- | :--- | :--- | :--- | :--- |
| **Argo CD** | `argocd` | `https://argocd.192.168.39.200.nip.io` | `192.168.39.200` | `admin` / (secret `argocd-initial-admin-secret`) |
| **Forgejo** | `forgejo` | `https://forgejo.192.168.39.201.nip.io` | `192.168.39.201` | `forgejoadmin` / `AdminForgejo2026!` |
| **CloudNativePG** | `cnpg-system` | In-Cluster Operator | N/A | Managed via CRDs |


