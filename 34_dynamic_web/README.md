### Динамический веб контент

Реализация стенда nginx + wordpress + ghost + gocd, каждый порт на свой сайт

http://192.168.100.10:2001 -> 8153 - gocd # go  
http://192.168.100.10:2002 -> 80 - wordpress # php  
http://192.168.100.10:2003 -> 2368 - ghost # js

Сервисы запускаются через docker-compose  
Nginx выполняет proxy_pass на указанные порты

![](img/web1.png)

![](img/web2.png)

![](img/web3.png)

SELinux выключен, т.к. иначе nginx не запускается и нет данных для отладки:
```
# sealert -a /var/log/audit/audit.log
100% done
found 0 alerts in /var/log/audit/audit.log
```
