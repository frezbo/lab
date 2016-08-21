#!/bin/bash
echo "vagrant:vagrant" | chpasswd
echo "root:centos" | chpasswd
hostnamectl set-hostname server1
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd
cat > /etc/resolv.conf << EOF
nameserver 192.168.33.254
domain example.com
EOF
echo "PEERDNS=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i.old /mirrorlist=.*repo=os/s/^/#/ /etc/yum.repos.d/CentOS-Base.repo
sed -i /mirrorlist=.*repo=updates/s/^/#/ /etc/yum.repos.d/CentOS-Base.repo
sed -i /mirrorlist=.*repo=extras/aenabled=0 /etc/yum.repos.d/CentOS-Base.repo
sed -i '/#baseurl=.*\/os/s/^#//' /etc/yum.repos.d/CentOS-Base.repo
sed -i '/#baseurl=.*\/updates/s/^#//' /etc/yum.repos.d/CentOS-Base.repo
sed -i /^baseurl=/s/mirror.centos.org/172.16.0.143/ /etc/yum.repos.d/CentOS-Base.repo
yum -y update
yum -y install net-tools bind-utils vim wget policycoreutils-python krb5-workstation acl
sed -i.old s/^#//g /etc/krb5.conf
sed -i s/kerberos/classroom/g /etc/krb5.conf
systemctl enable firewalld
systemctl restart firewalld
