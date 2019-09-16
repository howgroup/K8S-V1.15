#!/bin/bash
#howgroup@qq.com
source ./k8s_config
bash_path=$(cd "$(dirname "$0")";pwd)

if [[ "$(whoami)" != "root" ]]; then
	echo "please run this script as root ." >&2
	exit 1
fi

log="./setup.log"  #操作日志存放路径
fsize=2000000
exec 2>>$log  #如果执行过程中有错误信息均输出到日志文件中

echo -e "\033[31m 这个是centos7系统初始化脚本，请慎重运行!Please continue to enter or ctrl+C to cancel \033[0m"
#sleep 5

#安装kubenetes的相关包
set_k8s_repo(){
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
    yum -y install kubelet-1.15.0 kubeadm-1.15.0 kubectl-1.15.0 kubernetes-cni-0.7.5
    yum list installed | grep kube
    systemctl daemon-reload
    systemctl enable kubelet
    systemctl start kubelet
    echo "----set k8s_repo config OK!!"
}

#安装K8S的镜像
install_k8s_images(){
    images=(kube-scheduler:${k8s_version}
            kube-proxy:${k8s_version}
            kube-controller-manager:${k8s_version}
            kube-apiserver:${k8s_version}
            pause:3.1
            etcd:3.3.10)
    for imagename in ${images[@]}; do
    docker pull registry.aliyuncs.com/google_containers/$imagename
    docker tag registry.aliyuncs.com/google_containers/$imagename k8s.gcr.io/$imagename
    docker rmi registry.aliyuncs.com/google_containers/$imagename
    done
    docker pull registry.cn-hangzhou.aliyuncs.com/openthings/k8s-gcr-io-coredns:1.3.1
    docker tag registry.cn-hangzhou.aliyuncs.com/openthings/k8s-gcr-io-coredns:1.3.1 k8s.gcr.io/coredns:1.3.1
    docker rmi registry.cn-hangzhou.aliyuncs.com/openthings/k8s-gcr-io-coredns:1.3.1
    docker pull quay.io/coreos/flannel:v0.11.0-amd64

    echo "----install k8s images config OK!!"
}

#基于shar算法,生成token
token_shar_value(){
cd $bash_path
/usr/bin/kubeadm token list > token_shar_value.text
echo token_value=$(sed -n "2, 1p" token_shar_value.text | awk '{print $1}') >> k8s_config
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //' > token_shar_value.text
echo "sha_value=$(cat token_shar_value.text)"  >> k8s_config
rm -rf ./token_shar_value.text
echo "----token shar value OK!!"
}

#安装flannel网络
install_flannel(){
    wget https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml
    kubectl apply -f kube-flannel.yml
    echo "----install flannel OK!!"
}

#加入集群
join_cluster(){
  kubeadm join $masterip:6443 --token $token_value --discovery-token-ca-cert-hash sha256:$sha_value --control-plane --ignore-preflight-errors=all
}



main(){
 set_k8s_repo

 install_k8s_images
 install_flannel

 join_cluster
}
main > ./setup.log 2>&1
