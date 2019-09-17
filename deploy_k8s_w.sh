#!/bin/bash
#howgroup@qq.com
#get or refer from github, modify with own use and biz requirement

bash_path=$(cd "$(dirname "$0")";pwd)
source $bash_path/k8s_config


if [[ "$(whoami)" != "root" ]]; then  #check with user, it must be root
    echo "please run this script as root ." >&2
    exit 1
fi

log="./setup_w.log"  #log file path,操作日志存放路径
fsize=2000000
exec 2>>$log  #save all logs to setup log file,如果执行过程中有错误信息均输出到日志文件中

echo -e "\033[31m 这个是Kubernetes集群一键部署脚本,当前部署版本为V1.15.2！Please continue to enter after 5S or ctrl+C to cancel \033[0m"
sleep 5

#yum update,更新yum已经安装的软件
yum_update(){
	yum update -y
}

#configure yum source,配置yum的仓库路径，选择阿里云，将原有文件备份到bak目录下
yum_config(){
  yum install wget epel-release -y
  yum install -y tcl tclx tcl-devel expect openssh-clients
  if [[ $aliyun == "1" ]];then
  test -d /etc/yum.repos.d/bak/ || yum install wget epel-release -y && cd /etc/yum.repos.d/ && mkdir bak && mv -f *.repo bak/ && wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo && wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo && yum clean all && yum makecache
  fi
    echo "----yum config OK!!"
}

yum_init(){
num=0
while true ; do
let num+=1
yum -y install iotop iftop yum-utils net-tools git lrzsz expect gcc gcc-c++ make cmake libxml2-devel openssl-devel curl curl-devel unzip sudo ntp libaio-devel wget vim ncurses-devel autoconf automake zlib-devel  python-devel bash-completion
if [[ $? -eq 0 ]] ; then
echo "初始化安装环境配置完成!!!"
break;
else
if [[ num -gt 3 ]];then
echo "你登录 "$masterip" 看看,一直无法yum包."
break
fi
echo "没成功?再来一次!!"
fi
done
}

#firewalld,配置防火墙，关闭，禁用
iptables_config(){
if [[ `ps -ef | grep firewalld |wc -l` -gt 1 ]];then
  systemctl stop firewalld.service
  systemctl disable firewalld.service
  echo "----iptables config OK!!"
fi
}

#system config,配置系统的安全策略,禁用selinux,并且设置时钟同步服务,主时区为亚洲上海
system_config(){
grep "SELINUX=disabled" /etc/selinux/config
if [[ $? -eq 0 ]];then
  echo "SELINUX 已经禁用!!"
else
  sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
  setenforce 0
  echo "SELINUX 已经禁用!!"
fi

if [[ `ps -ef | grep chrony |wc -l` -eq 1 ]];then
  timedatectl set-local-rtc 1 && timedatectl set-timezone Asia/Shanghai
  yum -y install chrony && systemctl start chronyd.service && systemctl enable chronyd.service
  systemctl restart chronyd.service
  echo "时钟同步chrony服务安装完毕!!"
fi
}

#ulimit,修改内核参数,取消文件数量的限制
ulimit_config(){
grep 'ulimit' /etc/rc.local
if [[ $? -eq 0 ]];then
echo "内核参数调整完毕!!!"
else
  echo "ulimit -SHn 102400" >> /etc/rc.local
  cat >> /etc/security/limits.conf << EOF
  *           soft   nofile       102400
  *           hard   nofile       102400
  *           soft   nproc        102400
  *           hard   nproc        102400
  *           soft  memlock      unlimited
  *           hard  memlock      unlimited
EOF
  cat >> /etc/sysctl.conf << EOF
    kernel.pid_max=4194303
EOF
sysctl -p
echo "内核参数调整完毕!!!"
fi
}

#配置ssh安全策略,通过配置文件中的参数,设置ssh的访问
ssh_config(){
grep 'UserKnownHostsFile' /etc/ssh/ssh_config
if [[ $? -eq 0 ]];then
echo "ssh参数配置完毕!!!"
else
sed -i "2i StrictHostKeyChecking no\nUserKnownHostsFile /dev/null" /etc/ssh/ssh_config
echo "ssh参数配置完毕!!!"
fi
}

#set sysctl,配置K8S的系统管理
sysctl_config(){
  cp /etc/sysctl.conf /etc/sysctl.conf.bak
  cat > /etc/sysctl.conf << EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1
vm.swappiness=0
EOF
  /sbin/sysctl -p
  echo "----sysctl config OK!!"
}

#获取当前IP地址
get_localip(){
ipaddr=$(ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}' | grep $ip_segment)
echo "$ipaddr"
}


#install docker,安装当前指定的docker版本
install_docker() {
test -d /etc/docker
if [[ $? -eq 0 ]];then
echo "docker已经安装完毕!!!"
else
mkdir -p /etc/docker
yum-config-manager --add-repo  https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install -y --setopt=obsoletes=0 docker-ce-18.09.4-3.el7
tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://gpkhi0nk.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload
systemctl enable docker
systemctl restart docker
echo "docker已经安装完毕!!!"
fi
}

#swapoff,关闭swap交换分区
swapoff(){
grep 'vm.swappiness=0' /etc/sysctl.conf
if [[ $? -eq 0 ]];then
echo "临时命名空间删除!!!"
else
  /sbin/swapoff -a
  sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
  echo "vm.swappiness=0" >> /etc/sysctl.conf
  /sbin/sysctl -p
    echo "----swapoff config OK!!"
fi
}

#安装kubenetes的相关包
set_k8s_repo(){
test -f /etc/yum.repos.d/kubernetes.repo
if [[ $? -eq 0 ]];then
echo "kubelet kubectl kubeadm安装完毕!!!"
else
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
	yum -y install kubelet-1.15.2 kubeadm-1.15.2 kubectl-1.15.2 kubernetes-cni-0.7.5
	yum list installed | grep kube
	systemctl daemon-reload
	systemctl enable kubelet
	systemctl start kubelet
	echo "----set k8s_repo config OK!!"
fi
}

install_k8s_images(){
	images=(kube-scheduler:${k8s_version}
			kube-proxy:${k8s_version}
			kube-controller-manager:${k8s_version}
			kube-apiserver:${k8s_version}
			pause:3.1
			etcd:3.3.10)
	for imagename in ${images[@]}; do
	docker pull gcr.azk8s.cn/google-containers/$imagename
	docker tag gcr.azk8s.cn/google-containers/$imagename k8s.gcr.io/$imagename
	docker rmi gcr.azk8s.cn/google-containers/$imagename
	done
	docker pull registry.cn-hangzhou.aliyuncs.com/openthings/k8s-gcr-io-coredns:1.3.1
	docker tag registry.cn-hangzhou.aliyuncs.com/openthings/k8s-gcr-io-coredns:1.3.1 k8s.gcr.io/coredns:1.3.1
	docker rmi registry.cn-hangzhou.aliyuncs.com/openthings/k8s-gcr-io-coredns:1.3.1
	docker pull quay.io/coreos/flannel:v0.11.0-amd64
}

#安装flannel网络
install_flannel(){
    cd $bash_path
    kubectl apply -f kube-flannel.yml
    echo "flannel 网络配置完毕"
}

#加入集群
join_cluster(){
 kubeadm join $masterip:6443 --token $token_value --discovery-token-ca-cert-hash sha256:$sha_value
}

#设置K8S的系统环境
set_k8s_env(){
	mkdir -p /root/.kube
	cp /www/kube-cluster/kubeadm/K8S-V1.15/admin.conf /root/.kube/config
	chown $(id -u):$(id -g) /root/.kube/config
	cp -p /root/.bash_profile /root/.bash_profile.bak$(date '+%Y%m%d%H%M%S')
	echo "export KUBECONFIG=/root/.kube/config" >> /root/.bash_profile
	source /root/.bash_profile
}

check_cluster(){
kubectl get node
kubectl cluster-info

}


main(){
 #yum_update
  yum_config
  yum_init
  ssh_config
  iptables_config
  system_config
  ulimit_config
  swapoff
  install_docker
  set_k8s_repo

  install_k8s_images
  install_flannel
  join_cluster
  set_k8s_env
  check_cluster
  echo "k8s_$k8s_version 集群工作节点已经安装完毕，请登录相关服务器验收!"
}
main > ./setup_w.log 2>&1
