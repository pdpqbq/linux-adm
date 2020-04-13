### Настраиваем центральный сервер для сбора логов

В вагранте поднимаем 3 машины web, log, elk с адресами 192.168.33.10, 20, 30.

На web поднимаем nginx - http://192.168.33.10/. Включаем аудит конфигов nginx. Через плагин au-remote пересылаем логи аудита на log. Лог error.log посылаем в локальный journald и храним в нем критичные сообщения уровней 0-4. Лог access.log посылаем в rsyslog на log. Через сервис systemd-journal-upload пересылаем лог journald на log. Создаем сервис loggen, который генерирует сообщения с уровнями 1-5, делает touch конфига и обращается к nginx для наполнения аудита, access.log и error.log.

На сервере log включаем постоянное хранение лога journald и настраиваем сервис systemd-journal-remote для приема лога с web. Настраиваем rsyslog для приема access.log. Настраиваем auditd для приема лога аудита с web.

На сервере elk поднимаем elasticsearch logstash kibana. На сервере web ставим filebeat и настраиваем его на access.log.

log source | destination | service | host
---|---|---|---
/var/log/audit/audit.log | /var/log/audit/audit.log | auditd | log:60
journald level 0-4 | journald | systemd-journal-remote | log:19532
nginx access.log | /var/log/nginx_remote/access.log | rsyslog | log:514
nginx access.log | elk | logstash | elk:5044
nginx error.log | journald | unix:/dev/log | web

На сервере log:

- проверка журналов локального сервера - `journalctl -e | lnav`
- проверка журналов удаленного сервера - `journalctl -D /var/log/journal/remote/ -e | lnav`
- проверка аудита - `cat /var/log/audit/audit.log | grep node=web`
- проверка access.log - `cat /var/log/nginx_remote/access.log`

На сервере elk http://192.168.33.30:5601:

 - management - kibana - index patterns - create index pattern - index pattern => nginx-* - time filter => @timestamp - create
 - discover

Полезные команды:
 ```
 journalctl -p 1..3
 journalctl -o export -p 1..3 | /usr/lib/systemd/systemd-journal-remote -o /dir -
 journalctl -u nginx.service
 systemd-journal-upload --url http://192.168.33.20:19532/
 /usr/share/logstash/bin/logstash -t -f /etc/logstash/logstash-nginx.conf --path.settings /etc/logstash
```
