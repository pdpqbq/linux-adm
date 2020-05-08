#!/bin/bash

# centralRouter

#sysctl net.ipv4.conf.all.forwarding=1
echo "net.ipv4.conf.all.forwarding = 1" > /etc/sysctl.d/990-sysctl.conf
echo "DEFROUTE=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo "GATEWAY=192.168.255.1" >> /etc/sysconfig/network-scripts/ifcfg-eth2
#echo "192.168.200.200/32 via 192.168.255.5 dev eth3" > /etc/sysconfig/network-scripts/route-eth3
#echo "192.168.200.0/24 via 192.168.255.5 dev eth3" > /etc/sysconfig/network-scripts/route-eth3
