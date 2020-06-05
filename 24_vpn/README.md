### Мосты, туннели и VPN

Между двумя виртуалками server и client поднять vpn в режимах tun и tap

Файлы для этого задания - в каталоге files/1  
Для теста с ограничением по CPU настройка в вагрант-файле
```
config.vm.provider "virtualbox" do |v|
  v.customize ["modifyvm", :id, "--cpuexecutioncap", "20"]
end
```

Замеры скорости

TAP
```
vagrant@client ~]$ iperf3 -c 10.10.10.1 -t 30 -i 5
Connecting to host 10.10.10.1, port 5201
[  4] local 10.10.10.2 port 36088 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-5.00   sec   123 MBytes   206 Mbits/sec   70    173 KBytes       
[  4]   5.00-10.00  sec   127 MBytes   213 Mbits/sec  173    253 KBytes       
[  4]  10.00-15.00  sec   128 MBytes   215 Mbits/sec  131    257 KBytes       
[  4]  15.00-20.00  sec   128 MBytes   215 Mbits/sec   56    236 KBytes       
[  4]  20.00-25.01  sec   127 MBytes   213 Mbits/sec   49    177 KBytes       
[  4]  25.01-30.00  sec   128 MBytes   215 Mbits/sec   26    315 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-30.00  sec   761 MBytes   213 Mbits/sec  505             sender
[  4]   0.00-30.00  sec   760 MBytes   212 Mbits/sec                  receiver
```
TUN
```
[vagrant@client ~]$ iperf3 -c 10.10.10.1 -t 30 -i 5
Connecting to host 10.10.10.1, port 5201
[  4] local 10.10.10.2 port 36084 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-5.01   sec   129 MBytes   217 Mbits/sec   15    392 KBytes       
[  4]   5.01-10.00  sec   131 MBytes   219 Mbits/sec   50    279 KBytes       
[  4]  10.00-15.01  sec   132 MBytes   221 Mbits/sec   16    361 KBytes       
[  4]  15.01-20.00  sec   128 MBytes   216 Mbits/sec  242    133 KBytes       
[  4]  20.00-25.00  sec   127 MBytes   213 Mbits/sec   22    312 KBytes       
[  4]  25.00-30.01  sec   130 MBytes   218 Mbits/sec   88    342 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-30.01  sec   777 MBytes   217 Mbits/sec  433             sender
[  4]   0.00-30.01  sec   776 MBytes   217 Mbits/sec                  receiver
```
TAP + CPU limit
```
[vagrant@client ~]$ iperf3 -c 10.10.10.1 -t 30 -i 5
Connecting to host 10.10.10.1, port 5201
[  4] local 10.10.10.2 port 37106 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-5.00   sec  18.2 MBytes  30.5 Mbits/sec   11    139 KBytes       
[  4]   5.00-10.07  sec  17.3 MBytes  28.6 Mbits/sec   35    133 KBytes       
[  4]  10.07-15.00  sec  12.8 MBytes  21.8 Mbits/sec   35    149 KBytes       
[  4]  15.00-20.00  sec  16.1 MBytes  27.0 Mbits/sec   19    149 KBytes       
[  4]  20.00-25.01  sec  16.2 MBytes  27.1 Mbits/sec   13    119 KBytes       
[  4]  25.01-30.00  sec  16.4 MBytes  27.5 Mbits/sec   18    123 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-30.00  sec  96.9 MBytes  27.1 Mbits/sec  131             sender
[  4]   0.00-30.00  sec  96.4 MBytes  27.0 Mbits/sec                  receiver
```
TUN + CPU limit
```
[vagrant@client ~]$ iperf3 -c 10.10.10.1 -t 30 -i 5
Connecting to host 10.10.10.1, port 5201
[  4] local 10.10.10.2 port 37114 connected to 10.10.10.1 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-5.00   sec  15.7 MBytes  26.3 Mbits/sec   20    111 KBytes       
[  4]   5.00-10.00  sec  17.9 MBytes  30.0 Mbits/sec    6    133 KBytes       
[  4]  10.00-15.04  sec  17.3 MBytes  28.8 Mbits/sec    5    142 KBytes       
[  4]  15.04-20.00  sec  16.6 MBytes  28.0 Mbits/sec   21    117 KBytes       
[  4]  20.00-25.03  sec  13.6 MBytes  22.8 Mbits/sec   13    112 KBytes       
[  4]  25.03-30.00  sec  14.7 MBytes  24.8 Mbits/sec    9    114 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-30.00  sec  95.7 MBytes  26.8 Mbits/sec   74             sender
[  4]   0.00-30.00  sec  95.3 MBytes  26.7 Mbits/sec                  receiver
```
TAP + CPU limit + UDP
```
[vagrant@client ~]$ iperf3 -c 10.10.10.1 -t 30 -i 5 -u -V
iperf 3.1.7
Linux client.loc 3.10.0-957.12.2.el7.x86_64 #1 SMP Tue May 14 21:24:32 UTC 2019 x86_64
Control connection MSS 1321
Setting UDP block size to 1321
Time: Tue, 19 May 2020 01:29:55 GMT
Connecting to host 10.10.10.1, port 5201
      Cookie: client.loc.1589851795.961167.4620bcc
[  4] local 10.10.10.2 port 58175 connected to 10.10.10.1 port 5201
Starting Test: protocol: UDP, 1 streams, 1321 byte blocks, omitting 0 seconds, 30 second test
[ ID] Interval           Transfer     Bandwidth       Total Datagrams
[  4]   0.00-5.00   sec   628 KBytes  1.03 Mbits/sec  487  
[  4]   5.00-10.00  sec   640 KBytes  1.05 Mbits/sec  496  
[  4]  10.00-15.00  sec   640 KBytes  1.05 Mbits/sec  496  
[  4]  15.00-20.00  sec   640 KBytes  1.05 Mbits/sec  496  
[  4]  20.00-25.00  sec   640 KBytes  1.05 Mbits/sec  496  
[  4]  25.00-30.00  sec   640 KBytes  1.05 Mbits/sec  496  
- - - - - - - - - - - - - - - - - - - - - - - - -
Test Complete. Summary Results:
[ ID] Interval           Transfer     Bandwidth       Jitter    Lost/Total Datagrams
[  4]   0.00-30.00  sec  3.74 MBytes  1.05 Mbits/sec  0.045 ms  0/2967 (0%)  
[  4] Sent 2967 datagrams
CPU Utilization: local/sender 0.5% (0.2%u/0.4%s), remote/receiver 0.1% (0.0%u/0.0%s)
```
TUN + CPU limit + UDP
```
[vagrant@client ~]$ iperf3 -c 10.10.10.1 -t 30 -i 5 -u -V
iperf 3.1.7
Linux client.loc 3.10.0-957.12.2.el7.x86_64 #1 SMP Tue May 14 21:24:32 UTC 2019 x86_64
Control connection MSS 1353
Setting UDP block size to 1353
Time: Tue, 19 May 2020 01:33:17 GMT
Connecting to host 10.10.10.1, port 5201
      Cookie: client.loc.1589851997.237972.34b8f52
[  4] local 10.10.10.2 port 56719 connected to 10.10.10.1 port 5201
Starting Test: protocol: UDP, 1 streams, 1353 byte blocks, omitting 0 seconds, 30 second test
[ ID] Interval           Transfer     Bandwidth       Total Datagrams
[  4]   0.00-5.00   sec   628 KBytes  1.03 Mbits/sec  475  
[  4]   5.00-10.00  sec   641 KBytes  1.05 Mbits/sec  485  
[  4]  10.00-15.00  sec   640 KBytes  1.05 Mbits/sec  484  
[  4]  15.00-20.00  sec   640 KBytes  1.05 Mbits/sec  484  
[  4]  20.00-25.00  sec   641 KBytes  1.05 Mbits/sec  485  
[  4]  25.00-30.00  sec   640 KBytes  1.05 Mbits/sec  484  
- - - - - - - - - - - - - - - - - - - - - - - - -
Test Complete. Summary Results:
[ ID] Interval           Transfer     Bandwidth       Jitter    Lost/Total Datagrams
[  4]   0.00-30.00  sec  3.74 MBytes  1.05 Mbits/sec  0.081 ms  0/2897 (0%)  
[  4] Sent 2897 datagrams
CPU Utilization: local/sender 0.9% (0.3%u/0.5%s), remote/receiver 0.0% (0.0%u/0.0%s)
```
TAP работает в режиме моста, vpn-клиент находится в одном L2-сегменте с удаленной сетью и проходят широковещательные пакеты.
```
[root@server openvpn]# ip nei
10.10.10.2 dev tap0 lladdr b6:27:63:8b:54:6b REACHABLE

[root@server ~]# arping -I tap0 10.10.10.2
ARPING 10.10.10.2 from 10.10.10.1 tap0
Unicast reply from 10.10.10.2 [B6:27:63:8B:54:6B]  1.934ms
```
TUN работает в режиме маршрутизации, vpn-клиент находится в собственной подсети, пакеты в удаленную сеть маршрутизируются через openvpn.
```
[root@server openvpn]# ping 10.10.10.2
PING 10.10.10.2 (10.10.10.2) 56(84) bytes of data.
64 bytes from 10.10.10.2: icmp_seq=1 ttl=64 time=1.20 ms

[root@server openvpn]# arping -I tun0 10.10.10.2
arping: Device tun0 not available.

[root@server openvpn]# ip nei | grep 10.10.10.2
[root@server openvpn]# 
```







### Поднять RAS на базе OpenVPN с клиентскими сертификатами

Для выполнения этого задания настроим на сервере второй экземпляр openvpn с отдельной конфигурацией и создадим loopback с адресом 1.1.1.1/32, который будем пинговать с клиента rasclient. Файлы для этого задания - в каталоге files/2

После запуска ВМ отключаем SELinux

Устанавливаем easy-rsa3

Переходим в директорию /etc/openvpn/ и инициализируем pki
```
cd /etc/openvpn/ && /usr/share/easy-rsa/3/easyrsa init-pki
```
Создаем корневой сертификат
```
echo 'rasvpnCA' | /usr/share/easy-rsa/3/easyrsa build-ca nopass # pki/ca.crt
```
Создаем запрос на сертификат для сервера и после генерируем сам сертификат
```
echo 'rasvpnSRV' | /usr/share/easy-rsa/3/easyrsa gen-req server nopass # pki/private/server.key
echo 'yes' | /usr/share/easy-rsa/3/easyrsa sign-req server server # pki/issued/server.crt
```
Формируем ключ Диффи-Хеллмана
```
/usr/share/easy-rsa/3/easyrsa gen-dh # pki/dh.pem
```
Для создания ta ключа используем команду
```
openvpn --genkey --secret ta.key # ta.key
```
Сгенерируем сертификаты для клиента
```
echo 'rasvpnCL' | /usr/share/easy-rsa/3/easyrsa gen-req client nopass # pki/private/client.key
echo 'yes' | /usr/share/easy-rsa/3/easyrsa sign-req client client # pki/issued/client.crt
```
Генерируем список отозванных сертификатов
```
/usr/share/easy-rsa/3/easyrsa gen-crl # pki/crl.pem
```
Файл конфигурации сервера - rasserver.conf

Файл конфигурации клиента - rasclient.conf

Проверка
```
[vagrant@rasclient ~]$ ip r
default via 10.0.2.2 dev eth0 proto dhcp metric 101
1.1.1.1 via 192.168.254.5 dev tun0
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 101
192.168.20.0/24 dev eth1 proto kernel scope link src 192.168.20.30 metric 100
192.168.254.0/24 via 192.168.254.5 dev tun0
192.168.254.5 dev tun0 proto kernel scope link src 192.168.254.6

[vagrant@rasclient ~]$ ping 1.1.1.1
PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=64 time=1.16 ms

[vagrant@rasclient ~]# tracepath 1.1.1.1 -n
 1?: [LOCALHOST]                                         pmtu 1500
 1:  1.1.1.1                                               1.268ms reached
 1:  1.1.1.1                                               1.011ms reached
     Resume: pmtu 1500 hops 1 back 1

[vagrant@rasclient ~]$ iperf3 -c 1.1.1.1 -t 30 -i 5
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-30.01  sec  1.15 GBytes   330 Mbits/sec  2367             sender
[  4]   0.00-30.01  sec  1.15 GBytes   330 Mbits/sec                  receiver
```

### Настройка openconnect

Установка openconnect сервера на server
```
yum install ocserv -y
```
Установка openconnect клиента на rasclient
```
yum install openconnect -y
```
Будем использовать pam-аутентификацию. Возможные варианты - файл с паролями, сертификаты, RADIUS. Сертификаты для сервера возьмем из второго задания.

Изменим настройки в файле /etc/ocserv/ocserv.conf
```
server-cert = /etc/openvpn/pki/issued/server.crt
server-key = /etc/openvpn/pki/private/server.key
ca-cert = /etc/openvpn/pki/ca.crt
compression = true
ipv4-network = 192.168.199.0/24 # сеть для клиентов
dns = 8.8.8.8 # dns для клиентов
route = 1.1.1.1/255.255.255.255 # маршрут для клиентов
```
Старт сервера
```
[root@server log]# systemctl enable --now ocserv

[root@server log]# journalctl -fu ocserv
-- Logs begin at Tue 2020-05-19 23:37:28 UTC. --
May 20 00:48:31 server.loc ocserv[26930]: note: skipping 'pid-file' config option
May 20 00:48:31 server.loc ocserv[26930]: note: setting 'pam' as primary authentication method
May 20 00:48:31 server.loc ocserv[26930]: note: setting 'file' as supplemental config option
May 20 00:48:31 server.loc ocserv[26930]: listening (TCP) on 0.0.0.0:443...
```
Подключение клиента с использованием логина и пароля vagrant
```
[vagrant@rasclient ~]$ sudo systemctl stop openvpn@rasclient.service

[vagrant@rasclient ~]$ sudo openconnect https://192.168.20.10
POST https://192.168.20.10/
Connected to 192.168.20.10:443
SSL negotiation with 192.168.20.10
Server certificate verify failed: signer not found

Certificate from VPN server "192.168.20.10" failed verification.
Reason: signer not found
To trust this server in future, perhaps add this to your command line:
    --servercert sha256:a4dbd6965dc5b38730ef259eed620d9b5fd82c4e19af5835da8fc7a2449217c3
Enter 'yes' to accept, 'no' to abort; anything else to view: no
SSL connection failure: Error in the certificate.
Failed to open HTTPS connection to 192.168.20.10
Failed to obtain WebVPN cookie

[vagrant@rasclient ~]$ sudo openconnect https://192.168.20.10 --servercert sha256:a4dbd6965dc5b38730ef259eed620d9b5fd82c4e19af5835da8fc7a2449217c3
POST https://192.168.20.10/
Connected to 192.168.20.10:443
SSL negotiation with 192.168.20.10
Server certificate verify failed: signer not found
Connected to HTTPS on 192.168.20.10
XML POST enabled
Please enter your username.
Username:vagrant
POST https://192.168.20.10/auth
Please enter your password.
Password:
POST https://192.168.20.10/auth
Got CONNECT response: HTTP/1.1 200 CONNECTED
CSTP connected. DPD 90, Keepalive 32400
Connected as 192.168.199.120, using SSL + lz4
Established DTLS connection (using GnuTLS). Ciphersuite (DTLS1.2)-(PSK)-(AES-128-GCM).
DTLS connection compression using LZ4.
```
Проверка
```
[vagrant@rasclient ~]$ tracepath 1.1.1.1 -n
 1?: [LOCALHOST]                                         pmtu 1434
 1:  1.1.1.1                                               0.822ms reached
 1:  1.1.1.1                                               0.562ms reached
     Resume: pmtu 1434 hops 1 back 1

[vagrant@rasclient ~]$ ip r
default via 10.0.2.2 dev eth0 proto dhcp metric 101
1.1.1.1 dev tun0 scope link
8.8.8.8 dev tun0 scope link
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 101
192.168.20.0/24 dev eth1 proto kernel scope link src 192.168.20.30 metric 100
192.168.20.10 dev eth1 scope link src 192.168.20.30
192.168.199.0/24 dev tun0 scope link

[vagrant@rasclient ~]$ ip a
7: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1434 qdisc pfifo_fast state UNKNOWN group default qlen 500
    link/none
    inet 192.168.199.120/32 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::50fa:afc7:f5c2:a139/64 scope link flags 800
       valid_lft forever preferred_lft forever

[vagrant@rasclient ~]$ ping 1.1.1.1
PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=64 time=0.599 ms

[vagrant@rasclient ~]$ iperf3 -c 1.1.1.1 -t 30 -i 5
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-30.00  sec  1.19 GBytes   341 Mbits/sec  1904             sender
[  4]   0.00-30.00  sec  1.19 GBytes   341 Mbits/sec                  receiver

```
### Литература
- [Настраиваем OpenVPN сервер Linux на примере Ubuntu](https://howitmake.ru/blog/ubuntu/192.html)
- [Настраиваем OpenVPN клиент Linux на примере Ubuntu](https://howitmake.ru/blog/ubuntu/193.html)
- [Deploying AnyConnect Compatiable VPN Server With Certificate Verification on CentOS 7](https://www.vultr.com/docs/deploying-anyconnect-compatiable-vpn-server-with-certificate-verification-on-centos-7)
