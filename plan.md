
### Phase 1 — Kubernetes foundation - Completed

1. **Minikube + Podman + containerd + Cilium**
2. **Cilium + Hubble**
3. **Gateway API**
4. **cert-manager + local CA**
5. **Persistent storage**

### Phase 2 — GitOps bootstrap 

6. **Argo CD** - Completed

   * Deploy using Helm
   * Expose through Cilium Gateway
   * HTTPS via cert-manager
   * Verify local admin login

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

11. **Authentik**

    * Deploy using CloudNativePG PostgreSQL
    * Configure HTTPS
    * Create initial administrator
    * Configure OIDC provider/application for Argo CD
    * Verify Authentik itself

12. **Argo CD → Authentik OIDC**

    * Configure Argo CD OIDC
    * Map Authentik groups → Argo CD roles
    * Test login through Authentik
    * Keep the local `admin` account as emergency/bootstrap access

13. **Argo CD ↔ Forgejo**

    * Configure repository credentials
    * Create GitOps repository
    * Verify Argo CD can sync from Forgejo

### Phase 3 — App-of-Apps

At this point we have the critical chain:

```text
                    Authentik
                       │
                       │ OIDC
                       ▼
                    Argo CD
                       │
                       │ GitOps
                       ▼
                    Forgejo
                       │
                       │ CI
                       ▼
               Forgejo Runners
                       │
                       ▼
                    Harbor
```

And **only after that** we let the App-of-Apps take over the remaining platform:

```text
                       Argo CD
                          │
                     App-of-Apps
                          │
        ┌─────────────────┼──────────────────┐
        ▼                 ▼                  ▼
   Data Services      Platform           Observability
        │                 │                  │
   Valkey Operator     Harbor              OTel
   MongoDB              ...                Loki
                                          Mimir
                                          Tempo
                                          Grafana
```

There is one deliberate exception: **CloudNativePG and Garage need to be available before applications that depend on them can start.** We can either bootstrap those two before Argo CD or have Argo CD deploy them immediately as the first child applications. I'd prefer the latter where practical, because it keeps the manual bootstrap surface very small.

So the ideal end state is:

```text
MANUAL BOOTSTRAP
────────────────────────────────────────
Minikube
Cilium
Hubble
Gateway API
cert-manager
Storage
Argo CD
        │
        ▼
GITOPS
────────────────────────────────────────
CloudNativePG
Garage
Forgejo
Forgejo Runner
Authentik
Argo CD OIDC
Valkey Operator
Harbor
MongoDB
OTel
LGTM
Applications
```

And, importantly, **we'll test each transition before proceeding**. We won't install Authentik and immediately assume OIDC works; we'll actually log into Argo CD through Authentik and verify the group/role mapping before moving to the next step.
