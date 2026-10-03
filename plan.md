### Phase 1 — Kubernetes foundation

1. **Minikube + Podman + containerd + Cilium**
2. **Cilium + Hubble**
3. **Gateway API**
4. **cert-manager + local CA**
5. **Persistent storage**
6. **Argo CD (bootstrap only)**
   * Deploy Argo CD using Helm
   * Expose Argo CD through Cilium Gateway
   * Configure HTTPS via cert-manager
   * Verify local admin login

### Phase 2 — GitOps bootstrap (dependency order)

7. **CloudNativePG**
   * Deploy CloudNativePG operator
   * Create and verify a PostgreSQL cluster
   * Validate persistence

8. **Forgejo (bootstrap dependency for GitOps)**
   * Deploy Forgejo
   * Configure Forgejo PostgreSQL on CloudNativePG
   * Verify HTTPS + Git operations

9. **Argo CD ↔ Forgejo Git integration**
   * Push this repository to Forgejo
   * Update repo URLs in Argo CD app manifests to the actual Forgejo owner/repo path
   * Configure Argo CD repository credentials
   * Verify `root-apps` can sync from Forgejo

10. **Enable Argo CD App-of-Apps**
   * Apply `k8s/argocd/root-application.yaml`
   * Verify child applications are discovered and reconciling

11. **Garage**
   * Deploy S3-compatible storage via Argo CD
   * Configure persistence
   * Verify S3 operations

12. **Forgejo Runners**
   * Deploy/register runner
   * Execute a test CI workflow
   * Verify runner → Forgejo connectivity

13. **Authentik**
   * Deploy using CloudNativePG PostgreSQL
   * Configure HTTPS
   * Create initial administrator
   * Provision OIDC provider/application for Argo CD, Forgejo, Garage UI, Grafana, Harbor

14. **Argo CD → Authentik OIDC**
   * Configure Argo CD OIDC
   * Map Authentik groups → Argo CD roles
   * Support both UI callback and CLI SSO callback (`http://localhost:8085/auth/callback`)
   * Keep local `admin` account as emergency/bootstrap access

### Phase 3 — Platform expansion

15. **Metrics Server**
   * Deploy Metrics Server with Kubelet TLS trust
   * Verify `kubectl top nodes` and `kubectl top pods`

16. **LGTM Observability Stack**
   * Prometheus metrics collection & scrape jobs
   * Loki log aggregation
   * Tempo distributed tracing
   * OpenTelemetry Collector DaemonSet
   * Grafana with Authentik SSO & pre-provisioned dashboards

17. **Harbor Enterprise Container Registry**
   * Deploy Harbor with CloudNativePG PostgreSQL (`registry` DB)
   * Configure Garage S3 backend storage (`harbor-registry` bucket)
   * Configure Authentik OIDC SSO with automatic onboarding
   * Enable Trivy vulnerability scanner & Harbor Prometheus exporter
   * Verify image push and object storage backend
