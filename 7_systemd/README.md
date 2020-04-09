### Создать сервис и unit-файлы для этого сервиса:
- bash, python или другой скрипт, который мониторит log-файл на наличие ключевого слова;
- ключевое слово и путь к log-файлу должны браться из /etc/sysconfig/ (.service);
- сервис должен активироваться раз в 30 секунд (.timer).

Создаём файл с конфигурацией для сервиса в директории /etc/sysconfig - из неё сервис будет брать необходимые переменные:
```
[root@localhost ~]# cat /etc/sysconfig/watchlog
WORD="ALERT"
LOG=/var/log/watchlog.log
```
Создаем /var/log/watchlog.log и пишем туда строки плюс ключевое слово "ALERT":
```
[root@localhost ~]# cat /var/log/watchlog.log
1
2
3
ALERT
```
Создадим скрипт и сделаем его выполняемым chmod +x, команда logger отправляет лог в системный журнал:
```
[root@localhost ~]# cat /opt/watchlog.sh
#!/bin/bash
WORD=$1
LOG=$2
DATE=`date`
if grep $WORD $LOG &> /dev/null
then
  logger "$DATE: I found word, Master!"
else
  exit 0
fi
```
Создадим юнит для сервиса /etc/systemd/system/watchlog.service:
```
[Unit]
Description=My watchlog service
[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
```
Создадим юнит для таймера /etc/systemd/system/watchlog.timer (AccuracySec по-умолчанию 1 минута):
```
[Unit]
Description=Run watchlog script every 30 second
[Timer]
# Run every 30 second
OnUnitActiveSec=30s
Unit=watchlog.service
AccuracySec=5s
[Install]
WantedBy=multi-user.target
```
Стартуем timer и в логе появляется сообщение:
```
[root@localhost ~]# systemctl start watchlog.timer
```
```
[root@localhost ~]# tail -f /var/log/messages
Apr  2 15:01:35 localhost systemd: Starting My watchlog service...
Apr  2 15:01:35 localhost root: Thu Apr  2 15:01:35 UTC 2020: I found word, Master!
Apr  2 15:01:35 localhost systemd: Started My watchlog service.
Apr  2 15:02:08 localhost systemd: Starting My watchlog service...
Apr  2 15:02:08 localhost root: Thu Apr  2 15:02:08 UTC 2020: I found word, Master!
Apr  2 15:02:08 localhost systemd: Started My watchlog service.
Apr  2 15:02:43 localhost systemd: Starting My watchlog service...
Apr  2 15:02:43 localhost root: Thu Apr  2 15:02:43 UTC 2020: I found word, Master!
Apr  2 15:02:43 localhost systemd: Started My watchlog service.
```
```
[root@localhost ~]# systemctl list-timers
NEXT                         LEFT     LAST                         PASSED    UNIT                         ACTIVATES
Thu 2020-04-02 15:03:48 UTC  14s left Thu 2020-04-02 15:03:18 UTC  15s ago   watchlog.timer               watchlog.service
```

### Дополнить unit-файл сервиса httpd возможностью запустить несколько экземпляров сервиса с разными конфигурационными файлами

Для запуска нескольких экземпляров сервиса будем использовать шаблон в конфигурации файла окружения:
```
[root@localhost ~]# cp /usr/lib/systemd/system/httpd.service /usr/lib/systemd/system/httpd@.service
```
```
[root@localhost ~]# systemctl cat httpd@.service
# /usr/lib/systemd/system/httpd.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I <-------------- добавим параметр %I сюда
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
# We want systemd to give httpd some time to finish gracefully, but still want
# it to kill httpd after TimeoutStopSec if something went wrong during the
# graceful stop. Normally, Systemd sends SIGTERM signal right after the
# ExecStop, which would kill httpd. We are sending useless SIGCONT here to give
# httpd time to finish.
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```
В самом файле окружения (которых будет два) задается опция для запуска веб-сервера с необходимым конфигурационным файлом:
```
[root@localhost ~]# cat /etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf
[root@localhost ~]# cat /etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf
```
Соответственно в директории с конфигами httpd должны лежать два конфига, в нашем случае это будут first.conf и second.conf:
```
[root@localhost ~]# cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
[root@localhost ~]# cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf
```
Для удачного запуска, в конфигурационных файлах должны быть указаны уникальные для каждого экземпляра опции Listen и PidFile. Конфиги можно скопировать и поправить только второй, в нем должны быть опции:
```
PidFile /var/run/httpd-second.pid
Listen 8080
```
Запустим:
```
[root@localhost ~]# systemctl start httpd@first
[root@localhost ~]# systemctl start httpd@second
```
Проверить можно несколькими способами, например посмотреть какие порты слушаются:
```
[root@localhost ~]# ss -tnlp | grep http
LISTEN     0      128         :::8080          :::*         users:(("httpd",pid=24999,fd=4),("httpd",pid=24998,fd=4),("httpd",pid=24997,fd=4),("httpd",pid=24996,fd=4),("httpd",pid=24995,fd=4),("httpd",pid=24994,fd=4))
LISTEN     0      128         :::80            :::*         users:(("httpd",pid=24984,fd=4),("httpd",pid=24983,fd=4),("httpd",pid=24982,fd=4),("httpd",pid=24981,fd=4),("httpd",pid=24980,fd=4),("httpd",pid=24979,fd=4))
```




### Создать unit-файл(ы) для сервиса:
- Kafka, Jira или любой другой, у которого код успешного завершения не равен 0 (к примеру, приложение Java или скрипт с exit 143)
- ограничить сервис по использованию памяти
- ограничить сервис ещё по трём ресурсам, которые не были рассмотрены на лекции
- реализовать один из вариантов restart и объяснить почему выбран именно этот вариант
- реализовать активацию по .path или .socket

Будем использовать скрипт с exit code 143.
```
[root@localhost ~]# cat /opt/ex143.sh
#!/bin/bash
dd if=/dev/sda of=/dev/null bs=1M count=1000
exit 143
```
Создадим юнит для запуска с лимитами по процессору, памяти, количеству процессов, скорости чтения диска. После успешного завершения операции dd наш скрипт вернет код 143 и юнит его перезапустит.
```
[root@localhost ~]# systemctl cat ex143.service
# /etc/systemd/system/ex143.service
[Unit]
Description=script with exit code 143
[Service]
ExecStart=/opt/ex143.sh
CPUQuota=30%
MemoryLimit=10M
TasksMax=2
BlockIOAccounting=1
BlockIOReadBandwidth=/dev/sda 50M
Restart=on-success
SuccessExitStatus=143
[Install]
WantedBy=multi-user.target
```
Включим accounting:
```
[root@localhost ~]# cat /etc/systemd/system.conf | grep Accounting
DefaultCPUAccounting=yes
DefaultBlockIOAccounting=yes
DefaultMemoryAccounting=yes
DefaultTasksAccounting=yes
```
Запустим сервис и посмотрим нагрузку (перезапуск выключен Restart=no):
```
[root@localhost ~]# systemctl start ex143.service

[root@localhost ~]# systemd-cgtop
Path                                Tasks   %CPU   Memory  Input/s Output/s
/system.slice/ex143.service             2   6.9     9.9M        -        -

[root@localhost ~]# systemctl status ex143.service
● ex143.service - script with exit code 143
   Loaded: loaded (/etc/systemd/system/ex143.service; disabled; vendor preset: disabled)
   Active: active (running) since Thu 2020-04-02 20:16:47 UTC; 8s ago
 Main PID: 4090 (ex143.sh)
    Tasks: 2 (limit: 2)
   Memory: 9.8M (limit: 10.0M)
   CGroup: /system.slice/ex143.service
           ├─4090 /bin/bash /opt/ex143.sh
           └─4091 dd if=/dev/sda of=/dev/null bs=1M count=1000

[root@localhost ~]# systemctl status ex143.service
● ex143.service - script with exit code 143
   Loaded: loaded (/etc/systemd/system/ex143.service; disabled; vendor preset: disabled)
   Active: inactive (dead)

Apr 02 16:17:57 localhost.localdomain ex143.sh[3277]: 1000+0 records in
Apr 02 16:17:57 localhost.localdomain ex143.sh[3277]: 1000+0 records out
Apr 02 16:17:57 localhost.localdomain ex143.sh[3277]: 1048576000 bytes (1.0 GB) copied, 37.6709 s, 27.8 MB/s
```

Для активации сервиса по пути будем использовать файл /opt/monitor и юнит типа path:
```
[root@localhost ~]# systemctl cat ex143.path
# /etc/systemd/system/ex143.path
[Unit]
Description=monitor file
[Path]
Unit=ex143.service
PathExists=/opt/monitor
[Install]
WantedBy=multi-user.target
```
Сервис не активен (перезапуск включен Restart=on-success):
```
[root@localhost ~]# systemctl status ex143.service
● ex143.service - script with exit code 143
   Loaded: loaded (/etc/systemd/system/ex143.service; disabled; vendor preset: disabled)
   Active: inactive (dead) since Thu 2020-04-02 16:46:28 UTC; 59s ago
```
Активируем:
```
[root@localhost ~]# echo 1 > /opt/monitor
```
Сервис активен:
```
[root@localhost ~]# systemctl status ex143.service
● ex143.service - script with exit code 143
   Loaded: loaded (/etc/systemd/system/ex143.service; disabled; vendor preset: disabled)
   Active: active (running) since Thu 2020-04-02 16:47:36 UTC; 1s ago
 Main PID: 3882 (ex143.sh)
    Tasks: 2 (limit: 2)
   Memory: 9.9M (limit: 10.0M)
   CGroup: /system.slice/ex143.service
           ├─3882 /bin/bash /opt/ex143.sh
           └─3883 dd if=/dev/sda of=/dev/null bs=1M count=1000

Apr 02 16:47:36 localhost.localdomain systemd[1]: Started script with exit code 143.
```
Сервис активирован path-юнитом и перезапускается после успешного завершения. Останавливаем:
```
[root@localhost ~]# systemctl stop ex143.service
Warning: Stopping ex143.service, but it can still be activated by:
  ex143.path
```
