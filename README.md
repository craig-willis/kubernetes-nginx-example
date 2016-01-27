Walk-through of a set of simple nginx configurations under Kubernetes. This is basically the same as the Kubernetes 101 and 201 examples.

# Clone the example repo

```
$ git clone https://github.com/craig-willis/kubernetes-nginx-example.git
```

# Start local Kubernetes cluster and download kubectl

If you don't have it already, run the provided shell script.
```
$ ./kube-up-local.sh
```

# Pod Example

This example starts pod with a single nginx container:

```
$ kubectl create -f nginx-pod.yaml
 
$ kubectl get pods
NAME                   READY     STATUS    RESTARTS   AGE
k8s-master-127.0.0.1   3/3       Running   0          48m
nginx                  0/1       Running   0          8s
```

You can access the running container using curl:
```
curl http://$(kubectl get pod nginx -o go-template={{.status.podIP}})
```

Delete this pod, since we'll create a replication container next:
```
kubectl delete pod nginx
```


# Replication Controller Example

This example creates a replication controller that manages two nginx containers. 

```
$ kubectl create -f nginx-rc.yaml
```
 
List the replication controller using kubectl:
```
$ kubectl get rc
CONTROLLER         CONTAINER(S)   IMAGE(S)   SELECTOR    REPLICAS   AGE
nginx-controller   nginx          nginx      app=nginx   2          2m
```
 
List the pods/containers using kubectl:
```
$ kubectl get pods
NAME                     READY     STATUS              RESTARTS   AGE
k8s-master-127.0.0.1     3/3       Running             0          1h
nginx-controller-lu0ov   0/1       ContainerCreating   0          2s
nginx-controller-rvpru   0/1       ContainerCreating   0          2s
```

You can again access each nginx container via it's assigned IP:
```
$ curl http://$(kubectl get pod <pod name> -o go-template={{.status.podIP}})
```

While you can delete the replication controller (which will delete the running pods/containers), don't do it now since we need the replication controller running for the service.

```
$ kubectl delete rc nginx-controller 
```
 
# Service Example

This example assumes that you have a running replication controller, as above. 
 
```
$ kubectl create -f nginx-service.yaml 
```
 
List the services using kubectl:
```
$ kubectl get services
NAME            CLUSTER_IP   EXTERNAL_IP   PORT(S)    SELECTOR    AGE
kubernetes      10.0.0.1     <none>        443/TCP    <none>      53m
nginx-service   10.0.0.245   <none>        8000/TCP   app=nginx   1m
```
 
List the pods using kubectl:
```
$ kubectl get pods
NAME                     READY     STATUS    RESTARTS   AGE
k8s-master-127.0.0.1     3/3       Running   0          1h
nginx-controller-lu0ov   1/1       Running   0          7m
nginx-controller-rvpru   1/1       Running   0          7m
```
 
Now you can access the service endpoint using curl:
```
$ export SERVICE_IP=$(kubectl get service nginx-service -o go-template={{.spec.clusterIP}})
$ export SERVICE_PORT=$(kubectl get service nginx-service -o go-template'={{(index .spec.ports 0).port}}')
$ curl http://${SERVICE_IP}:${SERVICE_PORT}
```
 
Deleting the service only deletes the service, not the replication controller:
```
$ kubectl delete service nginx-service 
```
 
# Deployment Example

Can't seem to get these working.  Apparently deployments are part of a v1beta API and must be enabled using extensions.
http://kubernetes.io/v1.1/docs/user-guide/deployments.html# kubernetes-nginx-example
