# Test/education simple example of Helm Chart for MyNginx

## Installation (example):

```bash
kubectl create ns web
helm upgrade --install mynginx helm/mynginx/ --namespace web
```

## Installation with other values (examples):

```bash
helm upgrade --install mynginx helm/mynginx/ --namespace web --set service.spec.type=NodePort --set deployment.spec.replicas=5
# or 
helm upgrade --install mynginx helm/mynginx/ --namespace web --set service.spec.type=LoadBalancer --set deployment.spec.replicas=6
```

## View results (examples):

```bash
helm ls -n web
kubectl get all -n web
kubectl get all -n web -o wide
# Set default namespace:
kubectl config set-context --current --namespace=web
kubectl config get-contexts
# Port-forward:
nohup kubectl port-forward service/web-svc 8765:8888 &
# Curl:
curl 127.0.0.1:8765
curl 127.0.0.1:8765/kitty.html
curl 127.0.0.1:8765/basic_status
# If we have web-svc service with LoadBalancer type then we can curl with external address of LoadBalancer:
kubectl get service web-svc -o json | jq
kubectl get service web-svc -o jsonpath="{.status.loadBalancer.ingress[0].ip}"
LB_EXT_IP=$(kubectl get service web-svc -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
# Curl with external address of LoadBalancer:
curl http://$LB_EXT_IP:8888/
curl http://$LB_EXT_IP:8888/kitty.html
curl http://$LB_EXT_IP:8888/basic_status
```

