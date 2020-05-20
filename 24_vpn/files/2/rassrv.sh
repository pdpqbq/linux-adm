#!/bin/bash

cat > /etc/sysconfig/network-scripts/ifcfg-lo.1 << \EOF
DEVICE=lo:1
IPADDR=1.1.1.1
NETMASK=255.255.255.255
ONBOOT=yes
EOF
ifup lo.1

cd /etc/openvpn/ && /usr/share/easy-rsa/3/easyrsa init-pki
echo 'rasvpnCA' | /usr/share/easy-rsa/3/easyrsa build-ca nopass # pki/ca.crt
echo 'rasvpnSRV' | /usr/share/easy-rsa/3/easyrsa gen-req server nopass # pki/private/server.key
echo 'yes' | /usr/share/easy-rsa/3/easyrsa sign-req server server # pki/issued/server.crt
/usr/share/easy-rsa/3/easyrsa gen-dh # pki/dh.pem
openvpn --genkey --secret ta.key # ta.key
echo 'rasvpnCL' | /usr/share/easy-rsa/3/easyrsa gen-req client nopass # pki/private/client.key
echo 'yes' | /usr/share/easy-rsa/3/easyrsa sign-req client client # pki/issued/client.crt
/usr/share/easy-rsa/3/easyrsa gen-crl # pki/crl.pem
