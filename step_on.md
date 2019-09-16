# centos7 K8S-V1.15

一、下载脚本工程或更新脚本文件
---
1、下载脚本工程
```
yum -y install git
git clone https://github.com/howgroup/K8S-V1.15.git

cd K8S-V1.15 && chmod -R 755 .
chmod +x *.sh
编辑k8s_config里面的参数

./deploy_k8s.sh

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
1、下载脚本工程

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


安装缺省主服务器
./deploy_k8s.sh
安装其他主节点
./deploy_k8s_m.sh
安装工作节点
./deploy_k8s_w.sh


kubectl get node --all-namespaces
kubectl get pods -n kube-system
kubectl get pods --all-namespaces
kubectl describe node calico-node-jq2dh -n kube-system
kubectl describe node calico-node-hgrdj -n kube-system
kubectl describe pod calico-node-hgrdj -n kube-system
kubectl -n kube-system logs -f calico-node-hgrdj
