#!/bin/bash
#howgroup@qq.com
#get or refer from github, modify with own use and biz requirement

source ./k8s_config
bash_path=$(cd "$(dirname "$0")";pwd)


if [[ "$(whoami)" != "root" ]]; then  #check with user, it must be root
    echo "please run this script as root ." >&2
    exit 1
fi

log="./setup.log"  #log file path,操作日志存放路径
fsize=2000000
exec 2>>$log  #save all logs to setup log file,如果执行过程中有错误信息均输出到日志文件中

echo -e "\033[31m 这个是Kubernetes集群一键部署脚本,当前部署版本为V1.15.0！Please continue to enter after 5S or ctrl+C to cancel \033[0m"
sleep 5

#yum update,更新yum已经安装的软件
yum_update(){
  yum update -y
}

#configure yum source,配置yum的仓库路径，选择阿里云，将原有文件备份到bak目录下
yum_config(){
  yum install wget -y
  yum -y install epel-release
  yum install -y tcl tclx tcl-devel expect
  yum -y install iotop iftop yum-utils net-tools git lrzsz expect gcc gcc-c++ make cmake libxml2-devel openssl-devel curl curl-devel unzip sudo libaio-devel wget vim ncurses-devel autoconf zlib-devel  python-devel bash-completion

  cd /etc/yum.repos.d/ && mkdir bak && mv -f *.repo bak/
  wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
  wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
  yum clean all && yum makecache

  echo "----yum config OK!!"
}

#firewalld,配置防火墙，关闭，禁用
iptables_config(){
  systemctl stop firewalld.service
  systemctl disable firewalld.service
  iptables -P FORWARD ACCEPT
  echo "----iptables config OK!!"
}

#system config,配置系统的安全策略,禁用selinux,并且设置时钟同步服务,主时区为亚洲上海
sec_ntp_config(){
  sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
  setenforce 0
  timedatectl set-local-rtc 1 && timedatectl set-timezone Asia/Shanghai
  yum -y install chrony && systemctl start chronyd.service && systemctl enable chronyd.service
  systemctl restart chronyd.service
  echo "----security ntp config OK!!"
}

#ulimit,修改内核参数,取消文件数量的限制
ulimit_config(){
  echo "ulimit -SHn 102400" >> /etc/rc.local
  cat >> /etc/security/limits.conf << EOF
  *           soft   nofile       102400
  *           hard   nofile       102400
  *           soft   nproc        102400
  *           hard   nproc        102400
  *           soft  memlock      unlimited
  *           hard  memlock      unlimited
EOF

  echo "----ulimit config OK!!"

}
#配置ssh安全策略,通过配置文件中的参数,设置ssh的访问
ssh_config(){
if [[`grep 'UserKnownHostsFile' /etc/ssh/ssh_config`]];then
echo "pass"
else
sed -i "2i StrictHostKeyChecking no\nUserKnownHostsFile /dev/null" /etc/ssh/ssh_config
fi

echo "----ssh config OK!!"
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

#swapoff,关闭swap交换分区
swapoff(){
  /sbin/swapoff -a
  sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
  echo "vm.swappiness=0" >> /etc/sysctl.conf
  /sbin/sysctl -p
  echo "----swapoff config OK!!"
}

#获取当前IP地址
get_localip(){
ipaddr='172.0.0.1'
ipaddr=$(ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}' | grep $ip_segment)
echo "$ipaddr"
}

#安装内核所需的其他软件
setupkernel(){
 rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
 rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
 yum --enablerepo=elrepo-kernel install -y kernel-lt kernel-lt-devel
 grub2-set-default 0
 echo "----setup kernel config OK!!"
}

#根据配置文件,修改服务器名称,在同一个队列内的序号自动增加
change_hosts(){
    cd $bash_path
    num=0
    #rm -rf ./new_hostname_list.config
    #touch ./new_hostname_list.config
    for host in ${hostip[@]}
    do
    let num+=1
    if [ $host == `get_localip` ];then
    `hostnamectl set-hostname $hostname$num`
    echo $host `hostname` >> /etc/hosts
    #echo `hostname` >> ./new_hostname_list.config
    else
    echo $host $hostname$num >> /etc/hosts

    #echo $hostname$num >> ./new_hostname_list.config
    fi
    done
    echo "----change hosts config OK!!"
}


#生成本地ca的hash值,用于多个服务器之间的信任
ca_hash(){
hash_value=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
echo $hash_value
echo "----ca hash config OK!!"
}

#install docker,安装当前指定的docker版本
install_docker() {
yum-config-manager --add-repo  https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install -y --setopt=obsoletes=0 docker-ce-18.09.4-3.el7
systemctl start docker
systemctl enable docker
echo "----install docker OK!!"
}



#主程序入口
main(){
 #yum_update
  #setupkernel
  yum_config
  ssh_config
  iptables_config
  sec_ntp_config
  ulimit_config
  sysctl_config
  change_hosts
  swapoff
  install_docker
}
main > ./setup.log 2>&1
