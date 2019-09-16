# centos7 K8S-V1.15

һ�����ؽű����̻���½ű��ļ�
---
1�����ؽű�����
```
yum -y install git
git clone https://github.com/howgroup/K8S-V1.15.git

cd K8S-V1.15 && chmod -R 755 .
chmod +x *.sh
�༭k8s_config����Ĳ���

./deploy_k8s.sh

���ԭ����������װ��������ִ��clean������������
./clean_k8s.sh

```
2�����½ű��ļ�
```
git fetch --all
git reset --hard origin/master
git pull
chmod +x *.sh
```
������װK8S
---
1�����ؽű�����

������װ����̨
---
1�����ؽű�����
# ���������뵽dashboard�ļ��в���dashboard
```
cd dashboard
kubectl create -f .
```
Ȼ��鿴��������Լ���¼��node�ڵ�˿�

kubectl get service --all-namespaces | grep kubernetes-dashboard
��������
```
kube-system   kubernetes-dashboard   NodePort    10.101.25.47   <none>        443:31660/TCP   22m
��ô�������https://nodeIP:31660����¼
```
�鿴��¼ʱ���token
```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```


��װȱʡ��������
./deploy_k8s.sh
��װ�������ڵ�
./deploy_k8s_m.sh
��װ�����ڵ�
./deploy_k8s_w.sh


kubectl get node --all-namespaces
kubectl get pods -n kube-system
kubectl get pods --all-namespaces
kubectl describe node calico-node-jq2dh -n kube-system
kubectl describe node calico-node-hgrdj -n kube-system
kubectl describe pod calico-node-hgrdj -n kube-system
kubectl -n kube-system logs -f calico-node-hgrdj
