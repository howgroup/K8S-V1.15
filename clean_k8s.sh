#!/bin/bash
#howgroup@qq.com

    systemctl stop kubelet
    docker rm -f -v $(docker ps  -a -q)

    rm -rf /etc/kubernetes
    rm -rf  /var/lib/etcd
    rm -rf   /var/lib/kubelet
    rm -rf  $HOME/.kube/config
    iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X

    yum reinstall -y kubelet
    systemctl daemon-reload
    systemctl restart docker
    systemctl enable kubelet