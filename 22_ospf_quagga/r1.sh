#!/bin/bash

cat > /etc/sysconfig/network-scripts/ifcfg-lo.1 << \EOF
DEVICE=lo:1
IPADDR=1.1.1.1
NETMASK=255.255.255.255
ONBOOT=yes
EOF
ifup lo.1
