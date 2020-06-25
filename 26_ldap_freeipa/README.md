### LDAP

1. Установить FreeIPA
2. Написать Ansible playbook для конфигурации клиента

Vagrant поднимает стенд с FreeIPA сервером server и клиентом client, домен local.lan  
На сервере и клиенте отключаем управление resolv.conf через NetworkManager  
На клиенте указываем ip сервера в resolv.conf  
Запускаем установку ipa-server-install и ipa-client-install в unattended режиме

Проверка:
```
[root@server ~]# ipa user-find admin
--------------
1 user matched
--------------
  User login: admin
  Last name: Administrator
  Home directory: /home/admin
  Login shell: /bin/bash
  Principal alias: admin@LOCAL.LAN
  UID: 1045600000
  GID: 1045600000
  Account disabled: False
----------------------------
Number of entries returned 1
----------------------------
```
```
[root@server ~]# ipa user-add user1 --first=user1 --last=user1 --password
Password:
Enter Password again to verify:
------------------
Added user "user1"
------------------
  User login: user1
  First name: user1
  Last name: user1
  Full name: user1 user1
  Display name: user1 user1
  Initials: uu
  Home directory: /home/user1
  GECOS: user1 user1
  Login shell: /bin/sh
  Principal name: user1@LOCAL.LAN
  Principal alias: user1@LOCAL.LAN
  User password expiration: 20200625002557Z
  Email address: user1@local.lan
  UID: 1045600001
  GID: 1045600001
  Password: True
  Member of groups: ipausers
  Kerberos keys available: True
```
```
[root@server ~]# ssh user1@client.local.lan
Password:
Password expired. Change your password now.
Current Password:
New password:
Retype new password:
Creating home directory for user1.
-sh-4.2$ id
uid=1045600001(user1) gid=1045600001(user1) groups=1045600001(user1) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
-sh-4.2$
```
После перезагрузки FreeIPA может не запускаться из-за ошибки "Unit named-pkcs11.service has failed"  
Это исправляется командой hostnamectl set-hostname server.local.lan
