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
❯ minikube --version
Error: unknown flag: --version
See 'minikube --help' for usage.
[ble: exit 14]

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

## Kinikube with Cilium and Hubble


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
  --set k8sServiceHost=192.168.39.74 \
  --set k8sServicePort=8443 \
  --set hubble.enabled=true \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true
  --set  operator.replicas=1
```

```sh
helm upgrade cilium cilium/cilium \
  -n kube-system \
  --reuse-values \
  --set l2announcements.enabled=true \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=192.168.39.74 \
  --set k8sServicePort=8443

 kubectl -n kube-system rollout restart ds/cilium
daemonset.apps/cilium restarted

```

```sh

⎈ in k8s-platform (default) Cloudsea/private-cloud/minikube-fullstack 
❯ kubectl apply -f k8s/lb-ip-pool.yaml 
Warning: cilium.io/v2alpha1 CiliumLoadBalancerIPPool is deprecated; use cilium.io/v2 CiliumLoadBalancerIPPool
ciliumloadbalancerippool.cilium.io/minikube-lb-pool created

⎈ in k8s-platform (default) Cloudsea/private-cloud/minikube-fullstack 
❯ kubectl apply -f k8s/minikube-lbpool-announcement-policy.yaml 
error: no objects passed to apply
[ble: exit 1]

⎈ in k8s-platform (default) Cloudsea/private-cloud/minikube-fullstack 
❯ kubectl apply -f k8s/minikube-lbpool-announcement-policy.yaml 
ciliuml2announcementpolicy.cilium.io/minikube-l2 created

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
echo   LoadBalancer   10.110.75.175   192.168.39.200   80:32632/TCP   0s
^C[ble: EOF]                                                                                                                                                                    
[ble: exit 1]

⎈ in k8s-platform (default) Cloudsea/private-cloud/minikube-fullstack took 6s 
❯ curl http://192.168.39.200
curl: (7) Failed to connect to 192.168.39.200 port 80 after 3098 ms: Could not connect to server
[ble: exit 7]

⎈ in k8s-platform (default) Cloudsea/private-cloud/minikube-fullstack took 3s 
❯ curl -k https://192.168.39.200
curl: (7) Failed to connect to 192.168.39.200 port 443 after 3073 ms: Could not connect to server
[ble: exit 7]

⎈ in k8s-platform (default) Cloudsea/private-cloud/minikube-fullstack took 3s 
❯ k get svc -A
NAMESPACE     NAME           TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                  AGE
default       echo           LoadBalancer   10.110.75.175    192.168.39.200   80:32632/TCP             54s
default       kubernetes     ClusterIP      10.96.0.1        <none>           443/TCP                  13h
kube-system   cilium-envoy   ClusterIP      None             <none>           9964/TCP                 13h
kube-system   hubble-peer    ClusterIP      10.107.176.223   <none>           443/TCP                  13h
kube-system   hubble-relay   ClusterIP      10.97.146.65     <none>           80/TCP                   13h
kube-system   hubble-ui      ClusterIP      10.108.165.166   <none>           80/TCP                   13h
kube-system   kube-dns       ClusterIP      10.96.0.10       <none>           53/UDP,53/TCP,9153/TCP   13h

⎈ in k8s-platform (default) Cloudsea/private-cloud/minikube-fullstack 
❯ curl -vvv http://192.168.39.200
17:28:26.921557 [0-x] * [READ] client_reset, clear readers
17:28:26.921709 [0-0] * [SETUP] added
17:28:26.921803 [0-0] *   Trying 192.168.39.200:80...
17:28:26.921959 [0-0] * [SETUP] Curl_conn_connect(block=0) -> 0, done=0
17:28:27.922349 [0-0] * [SETUP] Curl_conn_connect(block=0) -> 0, done=0
17:28:28.923364 [0-0] * [SETUP] Curl_conn_connect(block=0) -> 0, done=0
17:28:29.924359 [0-0] * [SETUP] Curl_conn_connect(block=0) -> 0, done=0
17:28:30.029599 [0-0] * connect to 192.168.39.200 port 80 from 192.168.39.1 port 46458 failed: No route to host
17:28:30.029985 [0-0] * Failed to connect to 192.168.39.200 port 80 after 3108 ms: Could not connect to server
17:28:30.030358 [0-0] * [SETUP] Curl_conn_connect(block=0) -> 7, done=0
17:28:30.030579 [0-0] * [SETUP] Curl_conn_connect(), filter returned 7
17:28:30.030819 [0-0] * [WRITE] [OUT] done
17:28:30.030955 [0-0] * closing connection #0
curl: (7) Failed to connect to 192.168.39.200 port 80 after 3108 ms: Could not connect to server
[ble: exit 7]

⎈ in k8s-platform (default) Cloudsea/private-cloud/minikube-fullstack took 3s 
❯ LB_IP=$(kubectl get svc echo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "$LB_IP"
192.168.39.200

⎈ in k8s-platform (default) Cloudsea/private-cloud/minikube-fullstack 
❯ curl -v "http://$LB_IP/"
*   Trying 192.168.39.200:80...
* connect to 192.168.39.200 port 80 from 192.168.39.1 port 33214 failed: No route to host
* Failed to connect to 192.168.39.200 port 80 after 3080 ms: Could not connect to server
* closing connection #0
curl: (7) Failed to connect to 192.168.39.200 port 80 after 3080 ms: Could not connect to server
[ble: exit 7]

⎈ in k8s-platform (default) Cloudsea/private-cloud/minikube-fullstack took 3s 
❯ sudo arp-scan --interface=virbr2 "$LB_IP"
Interface: virbr2, type: EN10MB, MAC: 52:54:00:13:73:92, IPv4: 192.168.39.1
Starting arp-scan 1.10.0 with 1 hosts (https://github.com/royhills/arp-scan)

0 packets received by filter, 0 packets dropped by kernel
Ending arp-scan 1.10.0: 1 hosts scanned in 1.420 seconds (0.70 hosts/sec). 0 responded

⎈ in k8s-platform (default) Cloudsea/private-cloud/minikube-fullstack 
❯ kubectl -n kube-system exec ds/cilium -- \
  cilium-dbg service list
ID   Frontend                 Service Type   Backend                                
1    10.96.0.1:443/TCP        ClusterIP      1 => 192.168.39.74:8443/TCP (active)   
2    10.96.0.10:53/TCP        ClusterIP      1 => 10.0.0.107:53/TCP (active)        
3    10.96.0.10:53/UDP        ClusterIP      1 => 10.0.0.107:53/UDP (active)        
4    10.96.0.10:9153/TCP      ClusterIP      1 => 10.0.0.107:9153/TCP (active)      
5    10.97.146.65:80/TCP      ClusterIP      1 => 10.244.0.6:4245/TCP (active)      
6    10.107.176.223:443/TCP   ClusterIP      1 => 192.168.39.74:4244/TCP (active)   
7    10.108.165.166:80/TCP    ClusterIP      1 => 10.244.0.5:8081/TCP (active)      
8    0.0.0.0:32632/TCP        NodePort       1 => 10.0.0.190:80/TCP (active)        
11   10.110.75.175:80/TCP     ClusterIP      1 => 10.0.0.190:80/TCP (active)        
12   192.168.39.200:80/TCP    LoadBalancer   1 => 10.0.0.190:80/TCP (active)        

```
