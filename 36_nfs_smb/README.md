### Vagrant стенд для NFS

Стенд поднимает 2 виртуалки: сервер и клиент  
На сервере расшарена директория /var/share и в ней upload с правами на запись  
На клиента она автоматически монтируется при старте (fstab или autofs)  
Требования для NFS: NFSv3 по UDP, включенный firewall

Настройка сервера
```
# mkdir /var/share
# mkdir /var/share/upload
# chmod 777 /var/share/upload

# cat /etc/exports
/var/share 192.168.33.0/24(rw,sync,root_squash)
```

В файле /etc/sysconfig/nfs устанавливаем статические порты, отключаем tcp и оставляем только 3 версию
```
LOCKD_TCPPORT=32803
LOCKD_UDPPORT=32769
MOUNTD_PORT=892
STATD_PORT=662
STATD_OUTGOING_PORT=2020

RPCNFSDARGS="--no-tcp -N 2 -N 4 -V 3"

```
Перезапускаем сервис nfs-server

Настраиваем фаервол
```
systemctl enable --now firewalld
firewall-cmd --zone=public --remove-interface=eth1
firewall-cmd --zone=internal --add-interface=eth1
firewall-cmd --zone=internal --remove-service=dhcpv6-client
firewall-cmd --zone=internal --remove-service=mdns
firewall-cmd --zone=internal --remove-service=samba-client
#firewall-cmd --zone=internal --add-port=111/tcp
firewall-cmd --zone=internal --add-port=111/udp
#firewall-cmd --zone=internal --add-port=2049/tcp
firewall-cmd --zone=internal --add-port=2049/udp
#firewall-cmd --zone=internal --add-port=32803/tcp
firewall-cmd --zone=internal --add-port=32769/udp
#firewall-cmd --zone=internal --add-port=892/tcp
firewall-cmd --zone=internal --add-port=892/udp
#firewall-cmd --zone=internal --add-port=662/tcp
firewall-cmd --zone=internal --add-port=662/udp
firewall-cmd --runtime-to-permanent
firewall-cmd --reload
```
На клиенте включаем фаервол и указываем монтирование через fstab
```
192.168.33.10:/var/share /mnt/nfs_share nfs udp,rw
```
Проверка
```
192.168.33.10:/var/share on /mnt/nfs_share type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.33.10,mountvers=3,mountport=892,mountproto=udp,local_lock=none,addr=192.168.33.10)

[root@client /]# mkdir /mnt/nfs_share/1
mkdir: cannot create directory ‘/mnt/nfs_share/1’: Permission denied
[root@client /]# mkdir /mnt/nfs_share/upload/1
[root@client /]#

[root@server ~]# firewall-cmd --list-all --zone=internal
internal (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth1
  sources:
  services: ssh
  ports: 111/udp 2049/udp 32769/udp 892/udp 662/udp
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```
