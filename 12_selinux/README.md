### Практика с SELinux

1. Запустить nginx на нестандартном порту 3-мя разными способами:
- переключатели setsebool;
- добавление нестандартного порта в имеющийся тип;
- формирование и установка модуля SELinux.

2. Обеспечить работоспособность приложения при включенном selinux.
- Развернуть приложенный стенд
https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems
- Выяснить причину неработоспособности механизма обновления зоны (см. README);
- Предложить решение (или решения) для данной проблемы;
- Выбрать одно из решений для реализации, предварительно обосновав выбор;
- Реализовать выбранное решение и продемонстрировать его работоспособность.

### Запуск nginx на нестандартном порту

Меняем в /etc/nginx/nginx.conf порт 80 на 8888
```
# systemctl start nginx

nginx nginx[7078]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx nginx[7078]: nginx: [emerg] bind() to 0.0.0.0:8888 failed (13: Permission denied)
nginx nginx[7078]: nginx: configuration file /etc/nginx/nginx.conf test failed
nginx systemd[1]: nginx.service: control process exited, code=exited status=1
nginx systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
-- Subject: Unit nginx.service has failed
```
Смотрим контекст безопасности объекта
```
# ls -Z /usr/sbin/nginx
-rwxr-xr-x. root root system_u:object_r:httpd_exec_t:s0 /usr/sbin/nginx
```
Смотрим контекст безопасности процесса
```
# ps axZ | grep nginx
system_u:system_r:httpd_t:s0      663 ?        Ss     0:00 nginx: master process /usr/sbin/nginx
system_u:system_r:httpd_t:s0      666 ?        S      0:00 nginx: worker process
```
Поиск разрешающих правил для типа httpd_t
```
# sesearch -A -s httpd_t | grep "allow httpd_t"
```
Ищем правила преобразования, которые соответствуют этим типам
```
# sesearch -s httpd_t -t httpd_exec_t -c file -p execute -Ad
```
Запускаем анализ лога и получаем три способа настройки (нужен пакет setroubleshoot-server)
```
# sealert -a /var/log/audit/audit.log
```
Добавление нестандартного порта в имеющийся тип
```
# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989

# semanage port -a -t http_port_t -p tcp 8888
```
Переключатели setsebool
```
# semanage port -d -t http_port_t -p tcp 8888
# setsebool -P nis_enabled 1
```
Формирование и установка модуля SELinux
```
# setsebool -P nis_enabled 0
# ausearch -c 'nginx' --raw | audit2allow -M my-nginx
# semodule -i my-nginx.pp
# semodule -l | grep my-nginx
my-nginx	1.0

# ss -tlnp | grep 8888
LISTEN     0      128          *:8888                     *:*                   users:(("nginx",pid=1609,fd=6),("nginx",pid=1608,fd=6))
```
### BIND и SELinux

При попытке обновления динамической зоны с клиента получаем ошибку update failed: SERVFAIL

Из журнала /var/log/messages видим, что SELinux блокирует создание файла процессом isc-worker0000
```
named[5391]: /etc/named/dynamic/named.ddns.lab.view1.jnl: create: permission denied
setroubleshoot: SELinux is preventing isc-worker0000 from create access on the file named.ddns.lab.view1.jnl. For complete SELinux messages run: sealert -l f8844099-4a8a-421e-8f4c-7cef3bf05bff2
```
Детально смотрим лог
```
# sealert -l f8844099-4a8a-421e-8f4c-7cef3bf05bff2

If you want to allow isc-worker0000 to have create access on the named.ddns.lab.view1.jnl file
Then you need to change the label on named.ddns.lab.view1.jnl
Do
# semanage fcontext -a -t FILE_TYPE 'named.ddns.lab.view1.jnl'
where FILE_TYPE is one of the following: dnssec_trigger_var_run_t, ipa_var_lib_t, krb5_host_rcache_t, krb5_keytab_t, named_cache_t, named_log_t, named_tmp_t, named_var_run_t, named_zone_t.
Then execute:
restorecon -v 'named.ddns.lab.view1.jnl'


*****  Plugin catchall (17.1 confidence) suggests   **************************

If you believe that isc-worker0000 should be allowed create access on the named.ddns.lab.view1.jnl file by default.
Then you should report this as a bug.
You can generate a local policy module to allow this access.
Do
allow this access for now by executing:
# ausearch -c 'isc-worker0000' --raw | audit2allow -M my-iscworker0000
# semodule -i my-iscworker0000.pp


Additional Information:
Source Context                system_u:system_r:named_t:s0
Target Context                system_u:object_r:etc_t:s0
Target Objects                named.ddns.lab.view1.jnl [ file ]
Source                        isc-worker0000
Source Path                   isc-worker0000
Port                          <Unknown>
Host                          ns01
Source RPM Packages           
Target RPM Packages           
Policy RPM                    selinux-policy-3.13.1-266.el7.noarch
Selinux Enabled               True
Policy Type                   targeted
Enforcing Mode                Enforcing
Host Name                     ns01
Platform                      Linux ns01 3.10.0-1127.el7.x86_64 #1 SMP Tue Mar
                              31 23:36:51 UTC 2020 x86_64 x86_64
Alert Count                   1
First Seen                    2020-06-29 20:50:41 UTC
Last Seen                     2020-06-29 20:50:41 UTC
Local ID                      f8844099-4a8a-421e-8f4c-7cef3bf05bff

Raw Audit Messages
type=AVC msg=audit(1593463841.938:1990): avc:  denied  { create } for  pid=5401 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0


Hash: isc-worker0000,named_t,etc_t,file,create
```
```
# audit2why < /var/log/audit/audit.log
type=AVC msg=audit(1593463841.938:1990): avc:  denied  { create } for  pid=5401 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

	Was caused by:
		Missing type enforcement (TE) allow rule.

		You can use audit2allow to generate a loadable module to allow this access
```
Видно, что процесс с контекстом system_u:system_r:named_t:s0 пытается получить доступ к файлу с контекстом system_u:object_r:etc_t:s0
```
Source Context                system_u:system_r:named_t:s0
Target Context                system_u:object_r:etc_t:s0
Target Objects                named.ddns.lab.view1.jnl [ file ]
Source                        isc-worker0000
```
Предлагаются 2 решения - изменить контекст файла или загрузить модуль SELinux
```
# semanage fcontext -a -t named_cache_t "/etc/named/dynamic(/.*)?"
# restorecon -R -v /etc/named/dynamic/
restorecon reset /etc/named/dynamic context unconfined_u:object_r:etc_t:s0->unconfined_u:object_r:named_cache_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab context system_u:object_r:etc_t:s0->system_u:object_r:named_cache_t:s0
restorecon reset /etc/named/dynamic/named.ddns.lab.view1 context system_u:object_r:etc_t:s0->system_u:object_r:named_cache_t:s0
```
Обновление заработало
```
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
>
```
Здесь named_cache_t по аналогии с
```
# ll -Z /var/named/dynamic/
-rw-r--r--. named named system_u:object_r:named_cache_t:s0 default.mkeys
-rw-r--r--. named named system_u:object_r:named_cache_t:s0 default.mkeys.jnl
-rw-r--r--. named named system_u:object_r:named_cache_t:s0 view1.mkeys
-rw-r--r--. named named system_u:object_r:named_cache_t:s0 view1.mkeys.jnl
```
Пересоздаем стенд

Посмотрим содержимое модуля
```
# ausearch -c 'isc-worker0000' --raw | audit2allow -M my-iscworker0000
# cat my-iscworker0000.te

module my-iscworker0000 1.0;

require {
	type etc_t;
	type named_t;
	class file create;
}

#============= named_t ==============

#!!!! WARNING: 'etc_t' is a base type.
allow named_t etc_t:file create;
```
Загружаем модуль
```
# semodule -i my-iscworker0000.pp
```
Модуль загружен
```
# semodule -l | grep my-iscworker0000
my-iscworker0000	1.0
```
Обновления не работают
```
localhost named[5400]: /etc/named/dynamic/named.ddns.lab.view1.jnl: open: permission denied
```
Файл создался без права записи
```
-rw-rw----. 1 named named 509 Jun 29 21:32 named.ddns.lab
-rw-rw----. 1 named named 509 Jun 29 21:32 named.ddns.lab.view1
-rw-r--r--. 1 named named   0 Jun 29 21:42 named.ddns.lab.view1.jnl
```
Можно переделать модуль, скомпилировать и установить (из другой ветки решения, для инфо)
```
# semodule -r my-iscworker0000
# cat my-iscworker0000.te

module my-iscworker0000 1.0;

require {
	type etc_t;
	type named_cache_t;
	class file create;
}

#============= named_t ==============

#!!!! WARNING: 'etc_t' is a base type.
allow named_cache_t etc_t:file create;;
```
```
# checkmodule -M -m -o my-iscworker0000.mod my-iscworker0000.te
checkmodule:  loading policy configuration from my-iscworker0000.te
checkmodule:  policy configuration loaded
checkmodule:  writing binary representation (version 19) to my-iscworker0000.mod

# semodule_package -o my-iscworker0000.pp -m my-iscworker0000.mod
# semodule -i my-iscworker0000.pp
```
Уже другая ошибка
```
named[5401]: client @0x7f11e403c3e0 192.168.50.15#18738/key zonetransfer.key: view view1: updating zone 'ddns.lab/IN': error: journal open failed: no more
```
Выбрано решение без перенастройки SELinux - перенести файлы зоны ddns.lab в /var/named/dynamic как наиболее простое и рекомендованное производитетелем

https://kb.isc.org/docs/aa-00320
```
to allow named to update slave or DDNS zone files, it is best to locate them in $ROOTDIR/var/named/slaves, with named.conf zone statements
```

Исправленный конфиг named.conf.fix и плейбук playbook.yml.fix

```
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
>
> quit
[vagrant@client ~]$ dig @ns01 www.ddns.lab
;; ANSWER SECTION:
www.ddns.lab.		60	IN	A	192.168.50.15
;; SERVER: 192.168.50.10#53(192.168.50.10)
```
Разное
```
semanage user -l
chcat -L
sestatus
yum install mcstransd

setools-console
policycoreutils-python
policycoreutils-newrole

audit2why < /var/log/audit/audit.log
semanage  port -l | grep ssh
sealert -a /var/log/audit/audit.log
```
