#!/bin/bash

# external zone
cmd="ansible-playbook \
    --private-key=~/.vagrant.d/insecure_private_key \
    -u vagrant \
    -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory fw_fix_ext.yml \
    --limit"

for srv in ngx1 ngx2; do $cmd $srv; done

# internal zone
cmd="ansible-playbook \
    --private-key=~/.vagrant.d/insecure_private_key \
    -u vagrant \
    -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory fw_fix_int.yml \
    --limit"

for srv in ngx1 ngx2 app1 app2 app3 sqlp1 sqlp2 pxc1 pxc1 pxc3 adm1 adm2; do $cmd $srv; done

# fix gateway
cmd="ansible-playbook \
    --private-key=~/.vagrant.d/insecure_private_key \
    -u vagrant \
    -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory gw_fix.yml \
    --limit"

for srv in app1 app2 app3 sqlp1 sqlp2; do $cmd $srv; done
