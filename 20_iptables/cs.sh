#!/bin/bash

# centralServer

echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "GATEWAY=192.168.0.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
service network restart

#modprobe nf_conntrack
#modprobe nf_conntrack_ipv4

systemctl enable --now firewalld.service
firewall-cmd --zone=internal --add-interface=eth1
firewall-cmd --add-service=http --zone=internal
firewall-cmd --remove-service=dhcpv6-client --zone=internal
firewall-cmd --remove-service=samba-client --zone=internal
firewall-cmd --runtime-to-permanent
firewall-cmd --reload
