#!/bin/bash

# inetRouter2

echo "net.ipv4.conf.all.forwarding = 1" > /etc/sysctl.d/990-sysctl.conf
echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "192.168.0.0/24 via 192.168.255.6 dev eth1" > /etc/sysconfig/network-scripts/route-eth1
#iptables -t nat -A POSTROUTING ! -d 192.168.0.0/24 -o eth0 -j MASQUERADE

systemctl enable --now firewalld.service
firewall-cmd --remove-masquerade --zone=external
firewall-cmd --zone=internal --add-interface=eth1
firewall-cmd --zone=external --add-interface=eth2
firewall-cmd --add-forward-port=port=8080:proto=tcp:toaddr=192.168.0.2:toport=80 --zone=external
firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -p tcp -d 192.168.0.2 --dport 80 -j SNAT --to-source 192.168.255.5
firewall-cmd --runtime-to-permanent
firewall-cmd --reload
