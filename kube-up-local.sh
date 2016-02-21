PATH=$PATH:~/repos/kubernetes/_output/local/bin/linux/amd64/
HOSTNAME=`hostname`

etcd2 -data-dir `mktemp -d` --bind-addr 127.0.0.1:4001  > /tmp/etcd.log 2>&1 &

kube-apiserver --v=3 --cert-dir=/var/run/kubernetes --service-account-key-file=/tmp/kube-serviceaccount.key --service-account-lookup=false --admission-control=NamespaceLifecycle,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota --insecure-bind-address=127.0.0.1 --insecure-port=8080 --etcd-servers=http://127.0.0.1:4001 --service-cluster-ip-range=10.0.0.0/24 > /tmp/kube-apiserver.log 2>&1 &

kube-controller-manager --v=3 --service-account-private-key-file=/tmp/kube-serviceaccount.key --root-ca-file=/var/run/kubernetes/apiserver.crt --enable-hostpath-provisioner=false --master=127.0.0.1:8080 > /tmp/kube-controller.log 2>&1 &

kubelet --v=4 --chaos-chance=0.0 --container-runtime=docker --rkt-path= --rkt-stage1-image= --hostname-override="$HOSTNAME" --address=127.0.0.1 --api-servers=127.0.0.1:8080 --cpu-cfs-quota=false --cloud-provider=openstack --cloud-config=/tmp/cloud.conf > /tmp/kubelet.log 2>&1 &

