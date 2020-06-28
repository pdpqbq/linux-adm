### Настраиваем split-dns

Исходный стенд https://github.com/erlong15/vagrant-bind, добавляем client2  

* zones: dns.lab, reverse dns.lab and ddns.lab
* ns01 (192.168.50.11)
  * master, recursive, allows update to ddns.lab
* ns02 (192.168.50.12)
  * slave, recursive
* client1,2 (192.168.50.91,92)
  * used to test the env, runs rndc and nsupdate
* zone transfer: TSIG key

Исходные конфиги с небольшими изменениями - .conf.orig  
Конфиги для split-dns - .conf.split  
Стенд поднимается с конфигами split-dns и измененными файлами зон  
Версия BIND 9.11.4-P2-RedHat-9.11.4-16.P2.el7_8.6  
Решение начинается с оригинальных конфигов

Заводим в зоне dns.lab на ns01 имена web1 -> клиент1, web2 -> клиент2, прибавляем serial, перезагружаем named на ns01

named.dns.lab
```
client1 IN A 192.168.50.91
client2 IN A 192.168.50.92
web1 IN CNAME client1
web2 IN CNAME client2
```
named.dns.lab.rev
```
91 IN PTR client1.dns.lab.
92 IN PTR client2.dns.lab.
```
Проверка
```
[vagrant@client1 ~]$ dig @192.168.50.12 web2.dns.lab
;; ANSWER SECTION:
web2.dns.lab.		3600	IN	CNAME	client2.dns.lab.
client2.dns.lab.	3600	IN	A	192.168.50.92

[vagrant@client1 ~]$ dig @192.168.50.12 -x 192.168.50.92
;; ANSWER SECTION:
92.50.168.192.in-addr.arpa. 3600 IN	PTR	client2.dns.lab.50.168.192.in-addr.arpa.
```
Заводим еще одну зону newdns.lab и в ней запись www - смотрит на обоих клиентов

Добавляем в /etc/named.conf на ns01
```
// zone "newdns.lab"
zone "newdns.lab" {
    type master;
    allow-transfer { key "zonetransfer.key"; };
    file "/var/named/zones/named.newdns.lab";
};
```
Добавляем в /etc/named.conf на ns02
```
// zone "newdns.lab"
zone "newdns.lab" {
    type slave;
    masters { 192.168.50.11; };
    file "/var/named/zones/named.newdns.lab";
};
```
Создадим файл зоны и выставим права, иначе зона не загрузится с ошибкой
```
zone newdns.lab/IN: not loaded due to errors.
zone newdns.lab/IN: loading from master file /etc/named/named.newdns.lab failed: permission denied
```
```
[root@ns01 zones]# cat named.newdns.lab
$TTL 3600
$ORIGIN newdns.lab.
@               IN      SOA     ns01.dns.lab. root.dns.lab. (
                            1          ; serial
                            3600       ; refresh (1 hour)
                            600        ; retry (10 minutes)
                            86400      ; expire (1 day)
                            600        ; minimum (10 minutes)
                        )

                IN      NS      ns01.dns.lab.
                IN      NS      ns02.dns.lab.

www IN A 192.168.50.91
www IN A 192.168.50.92
```
```
[root@ns01 zones]# chown root:named named.newdns.lab
[root@ns01 zones]# chmod 660 named.newdns.lab
```
Перезапускаем bind, зоны синхронизируются, лог с ns02
```
systemctl restart named && tail -f /var/named/bind.log
```
```
named[4363]: all zones loaded
named[4363]: running
named[4363]: zone newdns.lab/IN: Transfer started.
named[4363]: transfer of 'newdns.lab/IN' from 192.168.50.11#53: connected using 192.168.50.12#58471 TSIG zonetransfer.key
named[4363]: zone newdns.lab/IN: transferred serial 1: TSIG 'zonetransfer.key'
named[4363]: transfer of 'newdns.lab/IN' from 192.168.50.11#53: Transfer status: success
named[4363]: transfer of 'newdns.lab/IN' from 192.168.50.11#53: Transfer completed: 1 messages, 6 records, 269 bytes, 0.001 secs (269000 bytes/sec)
```
Проверка - ответы чередуются
```
[vagrant@client1 ~]$ dig @192.168.50.12 www.newdns.lab
;; ANSWER SECTION:
www.newdns.lab.		3600	IN	A	192.168.50.91
www.newdns.lab.		3600	IN	A	192.168.50.92

[vagrant@client1 ~]$ dig @192.168.50.12 www.newdns.lab
;; ANSWER SECTION:
www.newdns.lab.		3600	IN	A	192.168.50.92
www.newdns.lab.		3600	IN	A	192.168.50.91
```
Настроим split-dns. Клиент1 - видит обе зоны, но в зоне dns.lab только web1. Клиент2 видит только dns.lab. Чтобы обновления с мастера попадали в правильный view на слейве, используется разделение по ключам view1.key и view2.key

На слейве ставим права на каталог с зонами для обхода ошибки
```
general: error: dumping master file: /var/named/zones/tmp-TJPybxVx1T: open: permission denied

mkdir /var/named/zones
chown root:named /var/named/zones
chmod 670 /var/named/zones
```

Файлы зон для клиента1  
named.dns.lab.view1  
named.dns.lab.view1.rev  
named.newdns.lab

Файлы зон для клиента2  
named.dns.lab  
named.dns.lab.rev

Конфиги для ns01 и ns02  
master-named.conf.split  
slave-named.conf.split

Проверка

Меняем на мастере named.dns.lab.view1, слейв обновляет view1
```
general: info: zone dns.lab/IN/view1: notify from 192.168.50.11#46485: serial 2711201470
general: info: zone dns.lab/IN/view1: Transfer started.
xfer-in: info: transfer of 'dns.lab/IN/view1' from 192.168.50.11#53: connected using 192.168.50.12#37079 TSIG view1.key
general: info: zone dns.lab/IN/view1: transferred serial 2711201470: TSIG 'view1.key'
xfer-in: info: transfer of 'dns.lab/IN/view1' from 192.168.50.11#53: Transfer status: success
xfer-in: info: transfer of 'dns.lab/IN/view1' from 192.168.50.11#53: Transfer completed: 1 messages, 8 records, 293 bytes, 0.001 secs (293000 bytes/sec)
```
Меняем на мастере named.dns.lab, слейв обновляет view2
```
general: info: zone dns.lab/IN/view2: notify from 192.168.50.11#55060: serial 2711201490
general: info: zone dns.lab/IN/view2: Transfer started.
xfer-in: info: transfer of 'dns.lab/IN/view2' from 192.168.50.11#53: connected using 192.168.50.12#60804 TSIG view2.key
general: info: zone dns.lab/IN/view2: transferred serial 2711201490: TSIG 'view2.key'
xfer-in: info: transfer of 'dns.lab/IN/view2' from 192.168.50.11#53: Transfer status: success
xfer-in: info: transfer of 'dns.lab/IN/view2' from 192.168.50.11#53: Transfer completed: 1 messages, 10 records, 337 bytes, 0.001 secs (337000 bytes/sec)
```
```
dig @192.168.50.11 web1.dns.lab
dig @192.168.50.11 web2.dns.lab
dig @192.168.50.11 www.newdns.lab

dig @192.168.50.12 web1.dns.lab
dig @192.168.50.12 web2.dns.lab
dig @192.168.50.12 www.newdns.lab
```
Разные команды
```
> /etc/named.conf && nano /etc/named.conf
systemctl restart named && tail -f /var/named/bind.log
named-checkconf
rndc -c rndc.conf -s ns01 reload
rndc -c rndc.conf -s ns01 flush

nsupdate -k /etc/named.zonetransfer.key
server IP
zone NAME
update add www.ddns.lab. 60 A IP
send
exit
```

### Литература

My secondary server for both an internal and an external view has both views transferred from the same primary view - how to resolve?
https://kb.isc.org/docs/aa-00296

Understanding views in BIND 9, by example
https://kb.isc.org/docs/aa-00851
