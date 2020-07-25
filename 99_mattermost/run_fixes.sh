#!/bin/bash

cmd="ansible-playbook \
    --private-key=~/.vagrant.d/insecure_private_key \
    -u vagrant \
    -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory fixes/fw_fix_ext.yml \
    --limit"

$cmd ngx1
$cmd ngx2

cmd="ansible-playbook \
    --private-key=~/.vagrant.d/insecure_private_key \
    -u vagrant \
    -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory fixes/fw_fix_int.yml \
    --limit"

$cmd ngx1
$cmd ngx2

$cmd app1
$cmd app2
$cmd app3

$cmd sqlp1
$cmd sqlp2

$cmd pxc1
$cmd pxc2
$cmd pxc3

$cmd adm1

cmd="ansible-playbook \
    --private-key=~/.vagrant.d/insecure_private_key \
    -u vagrant \
    -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory fixes/gw_fix.yml \
    --limit"

$cmd app1
$cmd app2
$cmd app3

$cmd sqlp1
$cmd sqlp2
