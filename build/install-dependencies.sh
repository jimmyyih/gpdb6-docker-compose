#! /bin/bash

yum install -y epel-release
yum install -y emacs-nox net-tools openssh-server openssh-clients python-devel
yum install -y python-pip

pip install psutil==4.0.0 pyyaml==5.3.1

wget https://golang.org/dl/go1.15.7.linux-amd64.tar.gz
tar -C /usr/local -xzvf go1.15.7.linux-amd64.tar.gz
rm -f go1.15.7.linux-amd64.tar.gz
