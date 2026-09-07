#!/usr/bin/env bash
set -e

PROFILE="k8s-platform"

echo "==> Starting Minikube ($PROFILE)..."
minikube start -p "$PROFILE"

echo "==> Waiting for Cilium CNI to become ready..."
cilium status --wait

echo "==> Refreshing application workloads to attach Cilium endpoints..."
kubectl rollout restart deploy,statefulset -n argocd -n forgejo -n garage -n cert-manager -n cnpg-system >/dev/null 2>&1 || true

echo "==> Cluster is ready!"
echo "    ArgoCD:     https://argocd.192.168.39.200.nip.io/"
echo "    Forgejo:    https://forgejo.192.168.39.201.nip.io/"
echo "    Garage UI:  https://garage.192.168.39.202.nip.io/"
echo "    Garage S3:  https://s3.192.168.39.202.nip.io/"
