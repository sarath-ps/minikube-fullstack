echo "=== 1. MINIKUBE ==="
minikube profile list

echo
echo "=== 2. NODE ==="
kubectl get nodes -o wide

echo
echo "=== 3. KUBE-PROXY SHOULD BE ABSENT ==="
kubectl -n kube-system get ds kube-proxy 2>&1
kubectl -n kube-system get cm kube-proxy 2>&1
kubectl -n kube-system get pods -l k8s-app=kube-proxy

echo
echo "=== 4. CILIUM ==="
cilium status --wait

echo
echo "=== 5. CILIUM KUBE-PROXY REPLACEMENT ==="
kubectl -n kube-system exec ds/cilium -- \
  cilium-dbg status | grep -E 'Cilium:|KubeProxyReplacement:|Kubernetes:|Hubble:'

echo
echo "=== 6. SERVICES ==="
kubectl get svc -A

echo
echo "=== 7. COREDNS ==="
kubectl -n kube-system get pods -l k8s-app=kube-dns -o wide

echo
echo "=== 8. HUBBLE ==="
kubectl -n kube-system get pods \
  -l k8s-app=hubble-relay \
  -o wide

kubectl -n kube-system get pods \
  -l k8s-app=hubble-ui \
  -o wide
  