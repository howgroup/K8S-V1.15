# centos7 K8S-V1.15

一、下载脚本工程或更新脚本文件
---
1、下载脚本工程
```
yum -y install git

创建目录
mkdir /www/kube-cluster/kubeadm
git clone https://github.com/howgroup/K8S-V1.15.git

cd K8S-V1.15 && chmod -R 755 .
chmod +x *.sh

如果原来服务器安装过，可先执行clean方法进行清理
./clean_k8s.sh

```
2、更新脚本文件
```
git fetch --all
git reset --hard origin/master
git pull
chmod +x *.sh
```


二、一体化安装K8S
---
```
./deploy_k8s_1.15.2_all.sh
```
后续查看日志

三、分步安装K8S
---
1、主节点安装
./deploy_k8s_1.15.2.sh
```
由于expect存在问题，暂时不使用./deploy_k8s_1.15.2_all.sh

```

2、主节点管理节点安装
```

同工作节点

运行如下命令：
设置时钟同步：./setclock_ntp.sh
安装节点，以管理节点方式加入集群: ./deploy_k8s_m.sh
```

3、工作节点安装
```
从主节点上，/www/kube-cluster/kubeadm/K8S-V1.15/k8s_config
覆盖K8S-V1.15下的文件

从主节点上，/etc/kubeletes下载admin.conf文件
将文件下载到本机 /www/kube-cluster/kubeadm/K8S-V1.15/admin.conf

设置脚本可执行
chmod +x *.sh

运行如下命令：
设置时钟同步：./setclock_ntp.sh
安装节点，以管理节点方式加入集群: ./deploy_k8s_w.sh

```

四、扩容服务器
---
同三，选择其中一个脚本运行


五、安装控制台
---
1、下载脚本工程
# 部署完后进入到dashboard文件夹部署dashboard
```
cd dashboard
kubectl create -f .
```
然后查看部署情况以及登录的node节点端口
kubectl get service --all-namespaces
kubectl get service --all-namespaces | grep kubernetes-dashboard
例如结果：
```
kube-system   kubernetes-dashboard   NodePort    10.101.25.47   <none>        443:31000/TCP   22m
那么你就输入https://nodeIP:31000来登录


kubectl -n kubernetes-dashboard edit service kubernetes-dashboard
kubectl edit service  kubernetes-dashboard-5c7687cf8-zk889 --namespace=kube-system
kubectl logs kubernetes-dashboard-5c7687cf8-zk889 --namespace=kube-system

```
查看登录时候的token
```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```


kubectl get node --all-namespaces
kubectl get pods -n kube-system -o wide
kubectl get pods --all-namespaces
kubectl describe node calico-node-jq2dh -n kube-system
kubectl describe node calico-node-hgrdj -n kube-system
kubectl describe pod calico-node-hgrdj -n kube-system
kubectl -n kube-system logs -f calico-node-hgrdj


cat ~/.ssh/id_rsa.pub | ssh ，<目标服务器IP地址> "umask 077; mkdir -p .ssh ; cat >> .ssh/authorized_keys"
curl -L https://raw.githubusercontent.com/beautifulcode/ssh-copy-id-for-OSX/master/install.sh | sh

chmod 755 /usr/local/bin/ssh-copy-id

yum -y install openssh-clients
