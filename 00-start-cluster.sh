#!/usr/bin/env bash
set -e

PROFILE="k8s-platform"

echo "==> Starting Minikube ($PROFILE)..."
minikube start -p "$PROFILE"

echo "==> Waiting for Cilium CNI to become ready..."
cilium status --wait

echo "==> Refreshing application workloads to attach Cilium endpoints..."
kubectl rollout restart deploy,statefulset -n argocd -n forgejo -n garage -n authentik -n monitoring -n cert-manager -n cnpg-system >/dev/null 2>&1 || true

echo "==> Cluster is ready!"
echo "    Authentik:  https://authentik.192.168.39.200.nip.io/ (Admin: akadmin / AdminAuthentik2026!)"
echo "    ArgoCD:     https://argocd.192.168.39.200.nip.io/ (Login with Authentik or local admin)"
echo "    Forgejo:    https://forgejo.192.168.39.200.nip.io/ (Login with Authentik, SSH: git@forgejo.192.168.39.200.nip.io:22)"
echo "    Grafana:    https://grafana.192.168.39.200.nip.io/ (Login with Authentik or admin / AdminGrafana2026!)"
echo "    Garage UI:  https://garage.192.168.39.200.nip.io/ (Login with Authentik or admin / AdminGarage2026!)"
echo "    Garage S3:  https://s3.192.168.39.200.nip.io/"
