### Строим бонды и вланы

Cервера с интерфесами и адресами в internal сети testLAN
- testClient1 - 10.10.10.254 - VL2
- testClient2 - 10.10.10.254 - VL3
- testServer1- 10.10.10.1 - VL2
- testServer2- 10.10.10.1 - VL3

Между centralRouter и inetRouter "пробросить" 2 линка (общая inernal сеть) и объединить их в бонд,
проверить работу c отключением интерфейсов
```
[vagrant@testClient1 ~]$ ip a
4: vlan2@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:80:c5:95 brd ff:ff:ff:ff:ff:ff
    inet 10.10.10.254/24 brd 10.10.10.255 scope global vlan2

[vagrant@testClient1 ~]$ ping testServer1
PING testServer1 (10.10.10.1) 56(84) bytes of data.
64 bytes from testServer1 (10.10.10.1): icmp_seq=1 ttl=64 time=1.18 ms

[vagrant@testClient1 ~]$ ip ne
10.10.10.1 dev vlan2 lladdr 08:00:27:20:e5:64 DELAY
```
```
[vagrant@testClient2 ~]$ ip a
4: vlan3@eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:c3:6e:a4 brd ff:ff:ff:ff:ff:ff
    inet 10.10.10.254/24 brd 10.10.10.255 scope global vlan3

[vagrant@testClient2 ~]$ ping testServer2
PING testServer2 (10.10.10.1) 56(84) bytes of data.
64 bytes from testServer2 (10.10.10.1): icmp_seq=1 ttl=64 time=0.442 ms

[vagrant@testClient2 ~]$ ip ne
10.10.10.1 dev vlan3 lladdr 08:00:27:2a:66:a5 REACHABLE
```
```
[vagrant@centralRouter ~]$ ip a
3: eth1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master bond0 state UP group default qlen 1000
    link/ether 08:00:27:45:a2:8f brd ff:ff:ff:ff:ff:ff
4: eth2: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master bond0 state UP group default qlen 1000
    link/ether 08:00:27:66:68:41 brd ff:ff:ff:ff:ff:ff
5: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:45:a2:8f brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.1/24 brd 10.0.0.255 scope global bond0
       valid_lft forever preferred_lft forever

[vagrant@centralRouter ~]$ ping 10.0.0.2
PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data.
64 bytes from 10.0.0.2: icmp_seq=1 ttl=64 time=2.93 ms

[vagrant@centralRouter ~]$ ip ne
10.0.0.2 dev bond0 lladdr 08:00:27:18:7d:87 REACHABLE

[vagrant@centralRouter ~]$ sudo ip link set eth1 down
[vagrant@centralRouter ~]$ ping 10.0.0.2
PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data.
64 bytes from 10.0.0.2: icmp_seq=1 ttl=64 time=3.01 ms

[vagrant@centralRouter ~]$ sudo ip link set eth1 up
[vagrant@centralRouter ~]$ sudo ip link set eth2 down
[vagrant@centralRouter ~]$ ping 10.0.0.2
PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data.
64 bytes from 10.0.0.2: icmp_seq=1 ttl=64 time=2.19 ms
```
```
[vagrant@inetRouter ~]$ ip a
3: eth1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master bond0 state UP group default qlen 1000
    link/ether 08:00:27:18:7d:87 brd ff:ff:ff:ff:ff:ff
4: eth2: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast master bond0 state UP group default qlen 1000
    link/ether 08:00:27:a8:a4:de brd ff:ff:ff:ff:ff:ff
5: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 08:00:27:18:7d:87 brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.2/24 brd 10.0.0.255 scope global bond0
       valid_lft forever preferred_lft forever

[vagrant@inetRouter ~]$ ping 10.0.0.1
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.
64 bytes from 10.0.0.1: icmp_seq=1 ttl=64 time=1.13 ms

[vagrant@inetRouter ~]$ sudo ip link set eth1 down
[vagrant@inetRouter ~]$ ping 10.0.0.1
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.

[vagrant@inetRouter ~]$ sudo ip link set eth1 up
[vagrant@inetRouter ~]$ sudo ip link set eth2 down
[vagrant@inetRouter ~]$ ping 10.0.0.1
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.
64 bytes from 10.0.0.1: icmp_seq=1 ttl=64 time=2.23 ms
```
