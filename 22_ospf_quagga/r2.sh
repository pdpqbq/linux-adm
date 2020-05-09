#!/bin/bash

cat > /etc/sysconfig/network-scripts/ifcfg-lo.1 << \EOF
DEVICE=lo:1
IPADDR=2.2.2.2
NETMASK=255.255.255.255
ONBOOT=yes
EOF
ifup lo.1
