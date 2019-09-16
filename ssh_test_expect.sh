#!/bin/bash
#howgroup@qq.com
#get or refer from github, modify with own use and biz requirement

bash_path=$(cd "$(dirname "$0")";pwd)
source $bash_path/k8s_config


if [[ "$(whoami)" != "root" ]]; then  #check with user, it must be root
    echo "please run this script as root ." >&2
    exit 1
fi

log="./setup.log"  #log file path,操作日志存放路径
fsize=2000000
exec 2>>$log  #save all logs to setup log file,如果执行过程中有错误信息均输出到日志文件中

echo -e "\033[31m 这个是Kubernetes集群一键部署脚本,当前部署版本为V1.15.2！Please continue to enter after 5S or ctrl+C to cancel \033[0m"
sleep 5

#获取当前IP地址
get_localip(){
ipaddr=$(ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}' | grep $ip_segment)
echo "$ipaddr"
}

#管理员的SSH信任配置,在没有rsa配置时,采用初始化exp外部文件,否则添加ssh用户
rootssh_trust_master(){
cd $bash_path
num=0
for host in ${hostip[@]}
do
let num+=1
if [[ `get_localip` != $host ]];then

    if [[ ! -f /root/.ssh/id_rsa.pub ]];then
    echo '###########init'
    expect ssh_trust_init.exp $root_passwd $host
    else
    echo '###########add'
    expect ssh_trust_add.exp $root_passwd $host
    fi
    echo "$host install k8s master please wait!!!!!!!!!!!!!!! "
    scp -P 7030 k8s_config setclock_ntp.sh deploy_k8s_m.sh ssh_trust_init.exp ssh_trust_add.exp root@$host:/root && scp -P 7030 /etc/hosts root@$host:/etc/hosts && ssh -p 7030 root@$host "hostnamectl set-hostname $hostname$num" && ssh -p 7030 root@$host /root/setclock_ntp.sh && ssh -p 7030 root@$host /root/deploy_k8s_m.sh

    echo "$host install k8s master success!!!!!!!!!!!!!!! "
fi
done

echo "----rootssh master config OK!!"
}

#管理员的SSH信任配置,在没有rsa配置时,采用初始化exp外部文件,否则添加ssh用户
rootssh_trust_worker(){
cd $bash_path
num=0
for host in ${hostip_worker[@]}
do
let num+=1
if [[ `get_localip` != $host ]];then

if [[ ! -f /root/.ssh/id_rsa.pub ]];then
echo '###########init'
expect ssh_trust_init.exp $root_passwd $host
else
echo '###########add'
expect ssh_trust_add.exp $root_passwd $host
fi
echo "$host install k8s worker please wait!!!!!!!!!!!!!!! "
scp -P 7030 k8s_config setclock_ntp.sh deploy_k8s_w.sh ssh_trust_init.exp ssh_trust_add.exp root@$host:/root && scp -P 7030 /etc/hosts root@$host:/etc/hosts && ssh -p 7030 root@$host "hostnamectl set-hostname $hostname_worker$num" && ssh -p 7030 root@$host /root/setclock_ntp.sh && ssh -p 7030 root@$host /root/deploy_k8s_w.sh

echo "$host install k8s worker success!!!!!!!!!!!!!!! "
fi
done

echo "----rootssh worker config OK!!"
}


check_cluster(){
kubectl get node
kubectl cluster-info
kubectl cluster-info dump
}


main(){

  rootssh_trust_master
  rootssh_trust_worker
  check_cluster
echo "k8s_$k8s_version 集群已经安装完毕，请登录相关服务器验收!"
}
main > ./setup.log 2>&1
