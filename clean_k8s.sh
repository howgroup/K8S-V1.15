#!/bin/bash
#howgroup@qq.com

    systemctl stop kubelet
    docker rm -f -v $(docker ps  -a -q)

    yum remove kubeadm
    yum remove kubelet
    yum remove kubectl

    rm -rf /etc/kubernetes
    rm -rf  /var/lib/etcd
    rm -rf   /var/lib/kubelet
    rm -rf  $HOME/.kube/config
    iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X

    systemctl daemon-reload
    systemctl restart docker