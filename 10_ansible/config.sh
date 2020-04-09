#!/bin/bash
ff=`grep inventory ansible.cfg | awk '{ print $3 }'`
echo "Get port and key from vagrant ssh config and put in $ff"
ap=`vagrant ssh-config | grep Port | awk '{ print $2 }'`
ak=`vagrant ssh-config | grep IdentityFile | awk '{ print $2 }'`
sed -i 's|ansible_port:.*|ansible_port: '$ap'|' $ff
sed -i "s|ansible_private_key_file:.*|ansible_private_key_file: $ak|" $ff
cat $ff
