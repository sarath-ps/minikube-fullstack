# Phase 1 — Kubernetes foundation

## 1. Minikube + Podman + containerd + Cilium

```sh

❯ podman run --rm hello-world
✔ docker.io/library/hello-world:latest
Trying to pull docker.io/library/hello-world:latest...
Getting image source signatures
Copying blob 4f55086f7dd0 done   | 
Copying config e2ac70e731 done   | 
Writing manifest to image destination

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/


Cloudsea/private-cloud/minikube-fullstack took 5s 
❯ minikube version
minikube version: v1.38.1
commit: c93a4cb9311efc66b90d33ea03f75f2c4120e9b0

Cloudsea/private-cloud/minikube-fullstack 
❯ 

Cloudsea/private-cloud/minikube-fullstack 
❯ curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
  % Total    % Received % Xferd  Average Speed  Time    Time    Time   Current
                                 Dload  Upload  Total   Spent   Left   Speed
  0      0   0      0   0      0      0      0                              0
  0      0   0      0   0      0      0      0                              0
100 136.0M 100 136.0M   0      0 14.29M      0   00:09   00:09         14.61M

Cloudsea/private-cloud/minikube-fullstack took 9s 
❯ sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

Cloudsea/private-cloud/minikube-fullstack 
❯ minikube version
minikube version: v1.39.0
commit: 7a9f6a841470a207de8cf4bafcccee0969d8ba10
```

```sh
❯ minikube config view
- rootless: true
- driver: podman
```

## Minikube with Cilium and Hubble


```sh
Cloudsea/private-cloud/minikube-fullstack 
❯ minikube start \
  --profile=k8s-platform \
  --driver=kvm2 \
  --container-runtime=containerd \
  --cpus=8 \
  --memory=32768 \
  --disk-size=200g \
  --extra-config=kubeadm.skip-phases=addon/kube-proxy

 helm install cilium cilium/cilium \
  --version 1.20.1 \
  --namespace kube-system \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=192.168.39.162 \
  --set k8sServicePort=8443 \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set operator.replicas=1
```

```sh
helm upgrade cilium cilium/cilium \
  -n kube-system \
  --reuse-values \
  --set l2announcements.enabled=true \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=192.168.39.162 \
  --set k8sServicePort=8443

 

```

```sh

⎈ in k8s-platform (default) Cloudsea/private-cloud/minikube-fullstack 
❯ kubectl apply -f k8s/lb-ip-pool.yaml 
Warning: cilium.io/v2alpha1 CiliumLoadBalancerIPPool is deprecated; use cilium.io/v2 CiliumLoadBalancerIPPool
ciliumloadbalancerippool.cilium.io/minikube-lb-pool created


⎈ in k8s-platform (default) Cloudsea/private-cloud/minikube-fullstack 
❯ kubectl apply -f k8s/minikube-lbpool-announcement-policy.yaml 
ciliuml2announcementpolicy.cilium.io/minikube-l2 created


> kubectl -n kube-system rollout restart ds/cilium
daemonset.apps/cilium restarted
```

```sh

⎈ in k8s-platform (default) Cloudsea/private-cloud/minikube-fullstack 
❯ kubectl create deployment echo \
  --image=nginx:alpine \
  --port=80

kubectl expose deployment echo \
  --port=80 \
  --target-port=80 \
  --type=LoadBalancer

kubectl get svc echo -w

deployment.apps/echo created
service/echo exposed
NAME   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
echo   LoadBalancer   10.110.75.175   192.168.39.200   80:32632/TCP                                                                        
```

```sh

kubectl apply --server-side \
  -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.1/standard-install.yaml


❯ kubectl get crd | grep gateway.networking.k8s.io

```

```sh
⎈ in k8s-platform (default) minikube-fullstack on  main [!] 
❯ helm upgrade cilium cilium/cilium \
  --namespace kube-system \
  --reuse-values \
  --set kubeProxyReplacement=true \
  --set gatewayAPI.enabled=true

⎈ in k8s-platform (default) minikube-fullstack on  main [!] took 2s 
❯ kubectl -n kube-system rollout restart deployment/cilium-operator
deployment.apps/cilium-operator restarted

⎈ in k8s-platform (default) minikube-fullstack on  main [!] 
❯ kubectl -n kube-system rollout restart daemonset/cilium
daemonset.apps/cilium restarted

```

```sh
kubectl -n gateway-test create deployment echo \
  --image=nginx:alpine \
  --port=80

kubectl -n gateway-test expose deployment echo \
  --port=80 \
  --target-port=80
```

## `cert-manager` and root CA

```
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

```
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

❯ k get all -n cert-manager 
NAME                                           READY   STATUS    RESTARTS   AGE
pod/cert-manager-66b9bfb996-vsjpq              1/1     Running   0          35s
pod/cert-manager-cainjector-5cc56c6f78-prnxm   1/1     Running   0          35s
pod/cert-manager-webhook-579c6dd789-lswwt      1/1     Running   0          35s

NAME                              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)            AGE
service/cert-manager              ClusterIP   10.100.196.252   <none>        9402/TCP           35s
service/cert-manager-cainjector   ClusterIP   10.109.183.31    <none>        9402/TCP           35s
service/cert-manager-webhook      ClusterIP   10.110.161.69    <none>        443/TCP,9402/TCP   35s

NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/cert-manager              1/1     1            1           35s
deployment.apps/cert-manager-cainjector   1/1     1            1           35s
deployment.apps/cert-manager-webhook      1/1     1            1           35s

NAME                                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/cert-manager-66b9bfb996              1         1         1       35s
replicaset.apps/cert-manager-cainjector-5cc56c6f78   1         1         1       35s
replicaset.apps/cert-manager-webhook-579c6dd789      1         1         1       35s


```

```
❯ k apply -f k8s/root-ca.yaml 
clusterissuer.cert-manager.io/selfsigned-bootstrap created
certificate.cert-manager.io/cloudsea-root-ca created

⎈ in minikube (default) minikube-fullstack on  feat/trial [!] 
❯ k apply -f k8s/local-ca.yaml 
clusterissuer.cert-manager.io/cloudsea-local-ca created

```

```
kubectl get secret -n cert-manager cloudsea-root-ca \
  -o jsonpath='{.data.tls\.crt}' | base64 -d > ./k8s/cloudsea-root-ca.crt

# sudo cp ./k8s/cloudsea-root-ca.crt /usr/local/share/ca-certificates/cloudsea-root-ca.crt # debian

sudo cp ./k8s/cloudsea-root-ca.crt /etc/pki/ca-trust/source/anchors/ $ redhat


sudo update-ca-certificates
```

### Generate Certificates

```
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f k8s/argocd/certificate.yaml

kubectl apply -f k8s/argocd/argocd-gateway.yaml

kubectl apply -f k8s/argocd/root-application.yaml


```