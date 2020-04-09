NGINX
==
Install nginx


Role Variables
--
nginx_listen_port: 8080


Dependencies
--
[ none ]


Example Playbook
--
```
- name: NGINX | Install and configure NGINX
  hosts: nginx
  become: true
  roles:
    - nginx
```
