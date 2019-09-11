# centos7 K8S-V1.15

k8s 1.15.0һ�������ַ��https://github.com/howgroup/K8S-V1.15


ע�����
```
1��ֻ��Ҫ���޸�k8s_config����Ĺ̶��������ɡ�
2����.sh��β�Ľű���Ȩ�ޡ�
3��Ȼ��ֻ��ִ��./deploy_k8s.sh�Ϳ�������
4��tail -f setup.log �鿴��־
5�����������˵�ˣ�Ҫ�������cpu����������2��Ŷ���м�
```


# ����k8s��Ⱥ����ʵ�ֲ��裺
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

# k8s_config�������ܣ�
```
masterIP��
masterip="10.26.1.17"

K8S�汾��
k8s_version="v1.15.0"

������root����
root_passwd=Wioc_2017!

��̨������������ǰ׺
���ڵ�ͽ�wioc-master01��wioc-master02
hostname=wioc-master0

node�ڵ��k8s2���κ���
�����ڵ�ͽ�wioc-worker01��wioc-worker02
hostnamenode=wioc-worker0

��Ⱥ������IP��ַ

hostip=��
10.26.1.17
10.26.1.10
��

hostip_worker=��
10.26.1.7
��
```
�ٲ����ʱ���ϸ�����������ʾ������дŶ����������Ҫ����ʽ���������

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
