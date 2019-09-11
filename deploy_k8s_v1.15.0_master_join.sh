#!/bin/bash
#howgroup@qq.com
#get or refer from github, modify with own use and biz requirement

source ./base_config_v1.15.0
bash_path=$(cd "$(dirname "$0")";pwd)


if [[ "$(whoami)" != "root" ]]; then  #check with user, it must be root
    echo "please run this script as root ." >&2
    exit 1
fi

log="./setup_master_join.log"  #log file path,操作日志存放路径
fsize=2000000
exec 2>>$log  #save all logs to setup log file,如果执行过程中有错误信息均输出到日志文件中

echo -e "\033[31m 这个是Kubernetes集群一键部署脚本,当前部署版本为V1.15.0！Please continue to enter after 5S or ctrl+C to cancel \033[0m"
sleep 5


#初始化K8S,join到集群中
init_k8s_master_join(){
    set -e
    rm -rf /root/.kube
    kubeadm reset -f

    #kubeadm init --kubernetes-version=$k8s_version --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$masterip

    kubeadm join $masterip:6443 --token $token \
    --discovery-token-ca-cert-hash sha256:$sha_value \

    mkdir -p /root/.kube
    cp /etc/kubernetes/admin.conf /root/.kube/config
    chown $(id -u):$(id -g) /root/.kube/config
    cp -p /root/.bash_profile /root/.bash_profile.bak$(date '+%Y%m%d%H%M%S')
    echo "export KUBECONFIG=/root/.kube/config" >> /root/.bash_profile
    source /root/.bash_profile
}


#主程序入口
main(){
  init_k8s_master_join
}

main > ./setup_master_join.log 2>&1
