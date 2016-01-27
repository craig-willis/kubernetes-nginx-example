

docker stop `docker ps -a | grep "gcr.*hyperkube kubelet" | awk '{print $1}'`
docker stop `docker ps -a | grep "gcr.*hyperkube control" | awk '{print $1}'`
docker stop `docker ps -a | grep "gcr.*hyperkube apiserver" | awk '{print $1}'`
docker stop `docker ps -a | grep "gcr.*hyperkube proxy" | awk '{print $1}'`
docker stop `docker ps -a | grep "gcr.*etcd" | awk '{print $1}'`
docker stop `docker ps -a | grep "gcr.*hyperkube scheduler" | awk '{print $1}'`
docker stop `docker ps -a | grep "gcr.*pause" | awk '{print $1}'`
