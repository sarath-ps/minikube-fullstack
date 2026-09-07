# Fullstack K8s Platform Using Minikube

An enterprise-grade private cloud platform running locally on Minikube with Cilium eBPF CNI, Gateway API, cert-manager, Argo CD (App-of-Apps), CloudNativePG, Authentik (OIDC SSO Identity Provider), Forgejo (with Actions Runner), and Garage S3 Object Storage (with Garage UI).

See [Plan](plan.md) for the roadmap and [Phase 1 Docs](docs/phase1.md) for foundational cluster setup notes.

---

## 🏛 Platform Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                   Cilium Gateway API (Shared IP: 192.168.39.200)                        │
│                           Listeners: 80 (HTTP) | 443 (HTTPS / Wildcard TLS) | 22 (SSH)                  │
└───────┬───────────────────────────────┬───────────────────────────────┬─────────────────────────┬───────┘
        │                               │                               │                         │
        │ https://authentik...          │ https://argocd...             │ https://forgejo...      │ https://garage...
        │ (OIDC / OAuth2 IdP)           │ (GitOps Engine)               │ (Git & CI/CD Actions)   │ (S3 UI & API)
        ▼                               ▼                               ▼                         ▼
┌──────────────────┐            ┌──────────────────┐            ┌──────────────────┐      ┌──────────────────────┐
│    Authentik     │◄───────────│     Argo CD      │            │     Forgejo      │      │      Garage S3       │
│ (Identity / SSO) │◄───────────────────────────────────────────│ (OAuth2 SSO)     │      │   Noooste/Garage-UI  │
└───────┬──────────┘◄─────────────────────────────────────────────────────────────────────│   (OIDC SSO Login)   │
        │                       │                               │                         └──────────────────────┘
        │ Uses CNPG DB          │ Manages Apps via App-of-Apps  │ Uses CNPG DB
        ▼                       ▼                               ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                             CloudNativePG Operator                               │
│                            (Namespace: cnpg-system)                              │
│  ┌──────────────────────────────────────────┐  ┌──────────────────────────────┐  │
│  │ authentik-postgres (PostgreSQL 16)       │  │ forgejo-postgres (PG 16)     │  │
│  └──────────────────────────────────────────┘  └──────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📂 Repository Layout

```text
.
├── 00-start-cluster.sh                  # Minikube startup & health recovery script
├── 00-verify-minikube-cilium.sh         # Foundation verification script
├── k8s/
│   ├── apps/
│   │   ├── authentik/                   # Authentik Identity Provider & OIDC SSO
│   │   │   ├── blueprints.yaml          # Auto-provisioning for Argo CD, Forgejo & Garage UI
│   │   │   ├── gateway.yaml             # HTTPRoute for authentik.192.168.39.200.nip.io
│   │   │   ├── kustomization.yaml       # Authentik Kustomize entrypoint
│   │   │   ├── namespace.yaml           # authentik namespace
│   │   │   ├── postgres.yaml            # CloudNativePG Cluster for Authentik
│   │   │   ├── secrets.yaml             # Secret key & bootstrap credentials
│   │   │   ├── server.yaml              # Authentik Web / Core Server Deployment
│   │   │   ├── service.yaml             # ClusterIP service (HTTP 9000 / HTTPS 9443)
│   │   │   └── worker.yaml              # Authentik Background Worker Deployment
│   │   ├── forgejo/                     # Forgejo Git service Kustomize package
│   │   │   ├── ca-configmap.yaml        # Local Root CA configmap for internal OIDC trust
│   │   │   ├── deployment.yaml          # Forgejo v10 Deployment with auto-init & OAuth2 setup
│   │   │   ├── gateway.yaml             # HTTPRoute & TCPRoute (SSH port 22)
│   │   │   ├── kustomization.yaml       # Kustomize entrypoint
│   │   │   ├── namespace.yaml           # forgejo namespace
│   │   │   ├── postgres.yaml            # CloudNativePG Cluster CR
│   │   │   ├── pvc.yaml                 # 10Gi standard PVC for Git repositories
│   │   │   ├── secrets.yaml             # Initial admin credentials & secret key
│   │   │   └── service.yaml             # ClusterIP service (HTTP 3000 / SSH 2222)
│   │   ├── forgejo-runner/              # Forgejo Actions Runner (CI/CD)
│   │   │   ├── deployment.yaml          # Act runner deployment (Docker-in-Docker)
│   │   │   ├── kustomization.yaml       # Runner Kustomize entrypoint
│   │   │   ├── rbac.yaml                # ServiceAccount and RBAC
│   │   │   └── secret.yaml              # Runner registration token & config
│   │   └── garage/                      # Garage S3 Object Storage & Web UI
│   │       ├── configmap.yaml           # garage.toml configuration
│   │       ├── gateway.yaml             # HTTPRoutes for S3 API & Garage UI
│   │       ├── kustomization.yaml       # Garage Kustomize entrypoint
│   │       ├── namespace.yaml           # garage namespace
│   │       ├── s3-credentials-secret.yaml # Default S3 access key secret
│   │       ├── secrets.yaml             # RPC secret & admin token
│   │       ├── service.yaml             # ClusterIP & Headless services
│   │       ├── statefulset.yaml         # Garage v2.1.0 StatefulSet
│   │       └── webui.yaml               # Noooste/garage-ui Deployment (OIDC configured)
│   ├── argocd/
│   │   ├── applications/                # Argo CD App-of-Apps child manifests
│   │   │   ├── authentik.yaml           # Authentik Identity Provider app
│   │   │   ├── cloudnative-pg.yaml      # CloudNativePG operator app
│   │   │   ├── forgejo.yaml             # Forgejo app
│   │   │   ├── forgejo-runner.yaml      # Forgejo runner app
│   │   │   └── garage.yaml              # Garage S3 app
│   │   ├── argocd-gateway.yaml          # Shared Gateway & HTTPRoute (192.168.39.200)
│   │   ├── certificate.yaml             # Wildcard TLS Certificate (*.192.168.39.200.nip.io)
│   │   ├── root-application.yaml        # Argo CD App-of-Apps root application
│   │   └── values.yaml                  # Argo CD Helm values (OIDC SSO with Authentik)
│   ├── platform/
│   │   └── cloudnative-pg/              # Platform Helm chart definition
│   ├── cloudsea-root-ca.crt             # Public Root CA certificate for local TLS
│   ├── lb-ip-pool.yaml                  # Cilium LoadBalancer IP pool (192.168.39.200 - 219)
│   ├── local-ca.yaml                    # cert-manager ClusterIssuer (cloudsea-local-ca)
│   ├── minikube-lbpool-announcement-policy.yaml # Cilium L2 Announcement policy
│   └── root-ca.yaml                     # Root CA certificate generator
├── docs/
│   └── phase1.md                        # Foundation documentation
└── plan.md                              # Implementation roadmap
```

---

## 📋 Platform Services & Access Endpoints

All HTTP/HTTPS services and TCP SSH traffic are consolidated on the shared IP **`192.168.39.200`** via Cilium Gateway API.

| Service | Hostname / URL | Port / Protocol | Credentials / Details |
| :--- | :--- | :--- | :--- |
| **Authentik** | `https://authentik.192.168.39.200.nip.io/` | `443 / HTTPS` | User: `akadmin`<br>Password: `AdminAuthentik2026!` |
| **Argo CD** | `https://argocd.192.168.39.200.nip.io/` | `443 / HTTPS` | **SSO**: Click "LOG IN VIA AUTHENTIK"<br>Local Admin: `admin` / retrieve from secret `argocd-initial-admin-secret` |
| **Forgejo (Web)** | `https://forgejo.192.168.39.200.nip.io/` | `443 / HTTPS` | **SSO**: Click "Authentik" button on Sign In page<br>Local Admin: `forgejoadmin` / `AdminForgejo2026!` |
| **Forgejo (SSH)** | `git@forgejo.192.168.39.200.nip.io` | `22 / TCP` | Authenticate via SSH public key |
| **Garage UI** | `https://garage.192.168.39.200.nip.io/` | `443 / HTTPS` | **SSO**: Click "Login with OIDC"<br>Local Admin: `admin` / `AdminGarage2026!` *(or use Admin Token)* |
| **Garage S3 API** | `https://s3.192.168.39.200.nip.io/` | `443 / HTTPS` | S3 Region: `garage`<br>Keys in `garage-s3-default-key` secret |

---

## 🚀 Quick Start Guide

### 1. Prerequisites & Foundation Setup

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

3. **Install cert-manager & Local Wildcard CA**:
   ```bash
   helm repo add jetstack https://charts.jetstack.io && helm repo update
   helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true
   kubectl apply -f k8s/root-ca.yaml
   kubectl apply -f k8s/local-ca.yaml
   ```

---

### 2. Install Argo CD & Shared Gateway

1. **Deploy Argo CD**:
   ```bash
   helm repo add argo https://argoproj.github.io/argo-helm && helm repo update
   helm install argocd argo/argo-cd -n argocd --create-namespace -f k8s/argocd/values.yaml
   kubectl apply -f k8s/argocd/certificate.yaml
   kubectl apply -f k8s/argocd/argocd-gateway.yaml
   ```

2. **Retrieve Initial Argo CD Password**:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
   ```

---

### 3. Deploy Forgejo & CloudNativePG

1. **Deploy Forgejo & Database**:
   ```bash
   kubectl apply -k k8s/apps/forgejo
   ```

2. **Push Platform Code into Forgejo**:
   ```bash
   # Add Forgejo remote and push repository
   git remote add origin git@forgejo.192.168.39.200.nip.io:forgejoadmin/minikube-fullstack.git
   git push -u origin main
   ```

---

### 4. Enable Argo CD App-of-Apps

Deploy the root application to manage all child applications via GitOps:

```bash
kubectl apply -f k8s/argocd/root-application.yaml
```

Argo CD will automatically sync:
- `cloudnative-pg` (PostgreSQL Operator)
- `authentik` (Identity Provider & OIDC SSO)
- `forgejo` (Git Repository & SSH)
- `forgejo-runner` (Actions CI/CD Runner)
- `garage` (S3 Object Storage & Garage Web UI)

---

### 5. Single Sign-On (SSO) with Authentik

Authentik automatically provisions OAuth2/OIDC applications and providers on first boot using declarative blueprints located in [`k8s/apps/authentik/blueprints.yaml`](k8s/apps/authentik/blueprints.yaml):

1. **Argo CD OIDC**:
   - Issuer: `https://authentik.192.168.39.200.nip.io/application/o/argocd/`
   - Callback: `https://argocd.192.168.39.200.nip.io/auth/callback`
   - Configured via Argo CD `oidc.config` with local Root CA trust.
2. **Forgejo OAuth2 / OIDC**:
   - Issuer: `https://authentik.192.168.39.200.nip.io/application/o/forgejo/`
   - Callback: `https://forgejo.192.168.39.200.nip.io/user/oauth2/authentik/callback`
   - Automatically registered via `forgejo admin auth add-oauth` in Forgejo container lifecycle.
3. **Garage UI OIDC**:
   - Issuer: `https://authentik.192.168.39.200.nip.io/application/o/garage-ui/`
   - Callback: `https://garage.192.168.39.200.nip.io/auth/oidc/callback`
   - Configured via `garage-ui` OIDC authentication provider.

---

### 6. Starting the Cluster After Reboot

When restarting Minikube or the host machine, run:

```bash
./00-start-cluster.sh
```

This script:
1. Starts the `k8s-platform` Minikube profile.
2. Waits for Cilium CNI to become healthy and ready.
3. Refreshes application pods to re-attach Cilium eBPF network endpoints.
4. Displays all active service URLs and credentials.


