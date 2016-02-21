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

The basic problem is that the openstack provider and cinder volume driver require the ability to mount the cinder volume to the kubelet host. Since the kubelet is running in a container, this isn't possible.


# Starting a non-Docker Kubernetes

Try to start the Kubernetes services locally, but without docker:
```
./kube-up-local.sh
```

This creates logs in /tmp.

# Start the nginx cinder instance

```
kubectl create -f nginx-cinder.yaml
```

This pod stays permanently in  "Pending" status. There's nothing in the logs, no errors, no mention of the configured volume ID.



# Kubelet log from Docker fail
W0220 18:24:26.399773   32765 server.go:585] Could not load kubeconfig file /var/lib/kubelet/kubeconfig: stat /var/lib/kubelet/kubeconfig: no such file or directory. Trying auth path instead.
W0220 18:24:26.399885   32765 server.go:547] Could not load kubernetes auth path /var/lib/kubelet/kubernetes_auth: stat /var/lib/kubelet/kubernetes_auth: no such file or directory. Continuing with defaults.
I0220 18:24:26.455021   32765 manager.go:128] cAdvisor running in container: "/system.slice/docker-52f472fe334c573da70acb5ccf10e0faeddb96db200a7927ff89b85d646f0cb0.scope"
I0220 18:24:26.725652   32765 fs.go:108] Filesystem partitions: map[/dev/vda4:{mountpoint:/rootfs/usr major:254 minor:4 fsType: blockSize:0} /dev/vda6:{mountpoint:/rootfs/usr/share/oem major:254 minor:6 fsType: blockSize:0} /dev/vda9:{mountpoint:/rootfs major:254 minor:9 fsType: blockSize:0}]
I0220 18:24:26.729701   32765 manager.go:163] Machine: {NumCores:2 CpuFrequency:2499996 MemoryCapacity:8377032704 MachineID:a89f0ef01fae4191a53039e7f65480af SystemUUID:D74F17E3-DB80-4BCC-BC67-C033A97682BB BootID:e1d78761-709d-41db-85fd-4e33edbb4bbd Filesystems:[{Device:/dev/vda4 Capacity:1031946240} {Device:/dev/vda6 Capacity:113229824} {Device:/dev/vda9 Capacity:39133392896}] DiskMap:map[254:0:{Name:vda Major:254 Minor:0 Size:42949672960 Scheduler:none}] NetworkDevices:[{Name:eth0 MacAddress:fa:16:3e:78:e8:94 Speed:0 Mtu:1454}] Topology:[{Id:0 Memory:8377032704 Cores:[{Id:0 Threads:[0] Caches:[{Size:32768 Type:Data Level:1} {Size:32768 Type:Instruction Level:1} {Size:4194304 Type:Unified Level:2}]}] Caches:[]} {Id:1 Memory:0 Cores:[{Id:0 Threads:[1] Caches:[{Size:32768 Type:Data Level:1} {Size:32768 Type:Instruction Level:1} {Size:4194304 Type:Unified Level:2}]}] Caches:[]}] CloudProvider:Unknown InstanceType:Unknown}
I0220 18:24:26.747794   32765 manager.go:169] Version: {KernelVersion:4.2.2-coreos-r2 ContainerOsVersion:Debian GNU/Linux 8 (jessie) DockerVersion:1.8.3 CadvisorVersion: CadvisorRevision:}
I0220 18:24:26.779634   32765 server.go:798] Adding manifest file: /etc/kubernetes/manifests
I0220 18:24:26.781296   32765 server.go:808] Watching apiserver
I0220 18:24:27.006229   32765 plugins.go:56] Registering credential provider: .dockercfg
E0220 18:24:27.020428   32765 kubelet.go:756] Image garbage collection failed: unable to find data for container /
I0220 18:24:27.021594   32765 server.go:770] Started kubelet
I0220 18:24:27.022629   32765 server.go:72] Starting to listen on 0.0.0.0:10250
I0220 18:24:27.043705   32765 kubelet.go:777] Running in container "/kubelet"
E0220 18:24:27.052417   32765 event.go:197] Unable to write event: 'Post http://localhost:8080/api/v1/namespaces/default/events: dial tcp 127.0.0.1:8080: connection refused' (may retry after sleeping)
I0220 18:24:27.490267   32765 factory.go:197] System is using systemd
I0220 18:24:27.953245   32765 factory.go:239] Registering Docker factory
I0220 18:24:27.960477   32765 factory.go:93] Registering Raw factory
I0220 18:24:28.609021   32765 manager.go:1006] Started watching for new ooms in manager
I0220 18:24:28.610173   32765 oomparser.go:183] oomparser using systemd
I0220 18:24:28.611176   32765 manager.go:250] Starting recovery of all containers
I0220 18:24:28.745122   32765 manager.go:255] Recovery completed
I0220 18:24:28.874923   32765 manager.go:104] Starting to sync pod status with apiserver
I0220 18:24:28.874992   32765 kubelet.go:1960] Starting kubelet main sync loop.
E0220 18:24:28.875180   32765 kubelet.go:1915] error getting node: node 'willis8-dev' is not in cache
E0220 18:24:28.884488   32765 kubelet.go:1356] Failed creating a mirror pod "k8s-master-willis8-dev_default": Post http://localhost:8080/api/v1/namespaces/default/pods: dial tcp 127.0.0.1:8080: connection refused
E0220 18:24:28.884617   32765 kubelet.go:1361] Mirror pod not available
PATH=$PATH:~/repos/kubernetes/_output/local/bin/linux/amd64/
W0220 18:24:28.895125   32765 manager.go:108] Failed to updated pod status: error updating status for pod "k8s-master-willis8-dev_default": Get http://localhost:8080/api/v1/namespaces/default/pods/k8s-master-willis8-dev: dial tcp 127.0.0.1:8080: connection refused
I0220 18:24:28.978418   32765 hairpin.go:49] Unable to find pair interface, setting up all interfaces: exec: "ethtool": executable file not found in $PATH
I0220 18:24:31.749868   32765 kubelet.go:900] Successfully registered node willis8-dev
W0220 18:24:36.321636   32765 cinder_util.go:107] Failed to find device for the diskid: "016af9cc-4530-4422-9eb8-95e1df993e62"
E0220 18:24:36.323332   32765 cinder_util.go:207] error running udevadm trigger fork/exec /usr/bin/udevadm: no such file or directory
E0220 18:24:38.890901   32765 kubelet.go:1361] Mirror pod not available
E0220 18:24:42.326675   32765 cinder_util.go:207] error running udevadm trigger fork/exec /usr/bin/udevadm: no such file or directory
E0220 18:24:42.370757   32765 kubelet.go:1383] Unable to mount volumes for pod "nginx_default": exit status 32; skipping pod
E0220 18:24:42.377057   32765 pod_workers.go:112] Error syncing pod 31655df8-d7ff-11e5-b1c8-fa163e78e894, skipping: exit status 32
E0220 18:24:43.243935   32765 openstack.go:810] Failed to attach 016af9cc-4530-4422-9eb8-95e1df993e62 volume to d74f17e3-db80-4bcc-bc67-c033a97682bb compute
E0220 18:24:43.244020   32765 kubelet.go:1383] Unable to mount volumes for pod "nginx_default": Expected HTTP response code [200] when accessing [POST http://nebula.ncsa.illinois.edu:8774/v2/3836c0d58e3349b28fc740e33a58a7e3/servers/d74f17e3-db80-4bcc-bc67-c033a97682bb/os-volume_attachments], but got 400 instead
{"badRequest": {"message": "Invalid volume: volume '016af9cc-4530-4422-9eb8-95e1df993e62' status must be 'available'. Currently in 'in-use'", "code": 400}}; skipping pod
E0220 18:24:43.249688   32765 pod_workers.go:112] Error syncing pod 31655df8-d7ff-11e5-b1c8-fa163e78e894, skipping: Expected HTTP response code [200] when accessing [POST http://nebula.ncsa.illinois.edu:8774/v2/3836c0d58e3349b28fc740e33a58a7e3/servers/d74f17e3-db80-4bcc-bc67-c033a97682bb/os-volume_attachments], but got 400 instead
{"badRequest": {"message": "Invalid volume: volume '016af9cc-4530-4422-9eb8-95e1df993e62' status must be 'available'. Currently in 'in-use'", "code": 400}}
