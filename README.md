# centos7 K8S-V1.15

k8s 1.15.0一键部署地址：https://github.com/howgroup/K8S-V1.15


注意事项：
```
1、只需要在修改base_config_v1.15.0里面的固定参数即可。
2、给.sh结尾的脚本赋权限。
3、然后只需执行./deploy_k8s_v1.15.0_master.sh就可以啦！
4、tail -f setup.log 查看日志
5、物理机不用说了，要是虚拟机cpu必须最少是2个哦！切记
```


# 部署k8s集群具体实现步骤：
```
git clone https://github.com/howgroup/K8S-V1.15.git

cd K8S-V1.15 && chmod -R 755 .

编辑base_config_v1.15.0里面的参数

./deploy_k8s_v1.15.0_master.sh

如果原来服务器安装过，可先执行clean方法进行清理
./clean_k8s.sh

```

# base_config_v1.15.0参数介绍：
```
masterIP：
masterip="10.26.1.17"

K8S版本：
k8s_version="v1.15.0"

服务器root密码
root_passwd=Wioc_2017!

多台主机的主机名前缀
主节点就叫wioc-master01，wioc-master02
hostname=wioc-master0

node节点叫k8s2依次后推
工作节点就叫wioc-worker01，wioc-worker02
hostnamenode=wioc-worker0

集群服务器IP地址

hostip=（
10.26.1.17
10.26.1.10
10.26.1.7
）

hostnodeip=（
10.26.1.7
）
```
再部署的时候严格按照我所给的示例参数写哦。换参数不要换格式，以免出错

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

