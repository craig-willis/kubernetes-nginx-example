# Create and initialize a cinder volume 

Install the cinder client:
```
docker run --rm -it deploy-heat bash
apt-get install -y python-cinderclient vim
```

Create and mount a volume (from deploy heat)
```
cinder create 10 --display-name willis8-vol-test 
nova volume-attach willis8-dev 016af9cc-4530-4422-9eb8-95e1df993e62
```

Initialize volume (from host)
```
sudo mkfs -t ext4 /dev/vdc
```

Detach the volume (from deploy-heat):
```
nova volume-detach willis8-dev 016af9cc-4530-4422-9eb8-95e1df993e62
cinder list
```

# Start Kubernetes

Create a cloud.conf file, adding your usename, password, and OpenStack tenant ID.

Change your hostname to match OpenStack, if not already
```
sudo hostnamectl set-hostname willis8-dev
```

Start Kubernetes via docker. Set HOSTNAME to the above hostname value (`hostname` and the OpenStack instance name must match):
```
./kube-up-docker.sh
```

Note that this uses the "openstack" provider and cloud.conf, which is required for cinder integration.


If the hostname override and `hostname` don't match, you'll see this error:
```
W0220 15:13:31.379205   24909 cinder_util.go:107] Failed to find device for the diskid: "016af9cc-4530-4422-9eb8-95e1df993e62"
```

# Start nginx with a volume

```
kubectl create -f nginx-cinder.yaml
```

The pod will remain in the pending state. 
```
docker logs <kubelet container id>
```

You'll see the following error:
```
E0220 18:13:00.785819   32104 openstack.go:810] Failed to attach 016af9cc-4530-4422-9eb8-95e1df993e62 volume to d74f17e3-db80-4bcc-bc67-c033a97682bb compute
```

The basic problem seems to be that the openstack provider and cinder volume driver require the ability to mount the cinder volume to the kubelet host. Since the kubelet is running in a container, this fails.


# Starting a non-Docker Kubernetes

Connect to your heat container, confirm that the volume is detached:
```
cinder list
nova volume-detach willis8-dev 016af9cc-4530-4422-9eb8-95e1df993e62
```

Try to start the Kubernetes services locally without docker:
```
hack/local-up-cluster.sh -o _output/local/bin/linux/amd64/
```

This creates logs in /tmp.
```
tail -f /tmp/kubelet.log
```

# Start the nginx cinder instance

```
cluster/kubectl.sh create -f ../kubernetes-nginx-example/nginx-cinder.yaml
cluster/kubectl.sh get pods
NAME      READY     STATUS    RESTARTS   AGE
nginx     1/1       Running   0          24s
```

Confirm the volume is mounted
```
cinder list
```

Stop the pod
```
cluster/kubectl.sh delete pod nginx
```

You'll see the following log entry:
```
Disk:  has no attachments or is not attached to compute: d74f17e3-db80-4bcc-bc67-c033a97682bb
```

The basic problem is that the cinder/openstack integration in Kubernetes is using the V1 Openstack blockstorage API, but Nebula is advertising the V2 API.

# Solutions?
* Modify existing Openstack/Cinder integration to use the V1 URL.  Nebula supports it.  By default, Kubernetes is using V2 because it's advertised by Nebula in the endpoints call
* Try to update the Openstack/Cinder integration to use V2. We can either implement our own version of the drivers or try to use the work being done by Rackspace.

This raises another question -- are we going to depend on Rackspace for Openstack support in Kubernetes?  Should we plan on developing our own NDS/NCSA provider?
