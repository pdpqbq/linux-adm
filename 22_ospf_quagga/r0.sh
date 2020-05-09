#!/bin/bash

setenforce 0
#yum update -y
echo "net.ipv4.conf.all.forwarding = 1" > /etc/sysctl.d/990-sysctl.conf
echo "net.ipv4.conf.eth1.rp_filter = 2" >> /etc/sysctl.d/990-sysctl.conf
echo "net.ipv4.conf.eth2.rp_filter = 2" >> /etc/sysctl.d/990-sysctl.conf
echo "net.ipv4.conf.all.rp_filter = 2" >> /etc/sysctl.d/990-sysctl.conf
echo "net.ipv4.conf.all.log_martians = 1" >> /etc/sysctl.d/990-sysctl.conf
service network restart
#touch /etc/quagga/ospfd.conf
chmod -R a+rw /etc/quagga/
systemctl enable --now zebra.zervice
systemctl enable --now ospfd.service
