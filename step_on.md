# centos7 K8S-V1.15

一、下载脚本工程或更新脚本文件
---
1、下载脚本工程
```
yum -y install git
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
二、安装K8S
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
创建目录
mkdir /www/kube-cluster/kubeadm
git clone https://github.com/howgroup/K8S-V1.15.git

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

三、安装控制台
---
1、下载脚本工程
# 部署完后进入到dashboard文件夹部署dashboard
```
cd dashboard
kubectl create -f .
```
然后查看部署情况以及登录的node节点端口

kubectl get service --all-namespaces | grep kubernetes-dashboard
例如结果：
```
kube-system   kubernetes-dashboard   NodePort    10.101.25.47   <none>        443:31660/TCP   22m
那么你就输入https://nodeIP:31660来登录
```
查看登录时候的token
```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```


kubectl get node --all-namespaces
kubectl get pods -n kube-system
kubectl get pods --all-namespaces
kubectl describe node calico-node-jq2dh -n kube-system
kubectl describe node calico-node-hgrdj -n kube-system
kubectl describe pod calico-node-hgrdj -n kube-system
kubectl -n kube-system logs -f calico-node-hgrdj
