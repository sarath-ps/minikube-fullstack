
### Phase 1 — Kubernetes foundation - Completed

1. **Minikube + Podman + containerd + Cilium**
2. **Cilium + Hubble**
3. **Gateway API**
4. **cert-manager + local CA**
5. **Persistent storage**
6. **Argo CD** - Completed
   * Deploy using Helm
   * Expose through Cilium Gateway
   * HTTPS via cert-manager
   * Verify local admin login


### Phase 2 — GitOps bootstrap - Completed

7. **CloudNativePG** - Completed
   * Deploy the operator
   * Create the PostgreSQL cluster
   * Verify database connectivity and persistence

8. **Garage** - Completed
   * Deploy S3-compatible storage
   * Configure persistence
   * Verify S3 operations

9. **Forgejo** - Completed
   * Deploy
   * Configure its PostgreSQL database
   * HTTPS
   * Verify Git operations

10. **Forgejo Runners** - Completed
    * Deploy/register
    * Execute a test CI workflow
    * Verify runner → Forgejo

11. **Authentik** - Completed
    * Deploy using CloudNativePG PostgreSQL
    * Configure HTTPS
    * Create initial administrator
    * Configure OIDC provider/application for Argo CD, Forgejo, Garage UI, Grafana, Harbor
    * Verify Authentik itself

12. **Argo CD → Authentik OIDC** - Completed
    * Configure Argo CD OIDC
    * Map Authentik groups → Argo CD roles
    * Test login through Authentik
    * Keep the local `admin` account as emergency/bootstrap access

13. **Argo CD ↔ Forgejo** - Completed
    * Configure repository credentials
    * Create GitOps repository
    * Verify Argo CD can sync from Forgejo

### Phase 3 — App-of-Apps & Platform Expansion - Completed

14. **Metrics Server** - Completed
    * Deploy Metrics Server with Kubelet TLS trust
    * Verify `kubectl top nodes` and `kubectl top pods`

15. **LGTM Observability Stack** - Completed
    * Prometheus metrics collection & scrape jobs
    * Loki log aggregation
    * Tempo distributed tracing
    * OpenTelemetry Collector DaemonSet
    * Grafana with Authentik SSO & pre-provisioned dashboards

16. **Harbor Enterprise Container Registry** - Completed
    * Deploy Harbor with CloudNativePG PostgreSQL (`registry` DB)
    * Configure Garage S3 backend storage (`harbor-registry` bucket)
    * Authentik OIDC SSO integration with automatic onboarding
    * Trivy vulnerability scanner & Harbor Prometheus exporter
    * Verified container image push and storage in Garage S3 backend
