### Настраиваем бэкапы с помощью BorgBackup

Настроить политику бэкапа директории /etc с клиента (server) на бекап сервер (backup):  
1) Бекап делаем раз в час  
2) Политика хранения бекапов: храним все за последние 30 дней, и по одному за предыдущие два месяца  
3) Настроить логирование процесса бекапа в /var/log/  
4) Восстановить из бекапа директорию /etc с помощью опции Borg mount  
5) Настроить репозиторий для резервных копий с шифрованием ключом

Vagrant поднимает стенд с двумя виртуальными машинами и настраивает ssh ключи для root-а

Инициализируем репозиторий с шифрованием, пароль пустой
```
[root@server ~]# borg init -e repokey-blake2 root@backup:files-etc
Enter new passphrase:
Enter same passphrase again:
Do you want your passphrase to be displayed for verification? [yN]: n

By default repositories initialized with this version will produce security
errors if written to with an older version (up to and including Borg 1.0.8).

If you want to use these older versions, you can disable the check by running:
borg upgrade --disable-tam ssh://backup/./files-etc

See https://borgbackup.readthedocs.io/en/stable/changes.html#pre-1-0-9-manifest-spoofing-vulnerability for details about the security implications.

IMPORTANT: you will need both KEY AND PASSPHRASE to access this repo!
Use "borg key export" to export the key, optionally in printable format.
Write down the passphrase. Store both at safe place(s).
```
Сохраняем ключ
```
[root@server ~]# borg key export backup:files-etc keyfile

[root@server ~]# cat keyfile
BORG_KEY ...
```
Создаем скрипт backup-data.sh
```
[root@server ~]# chmod +x backup-data.sh
```
Политика хранения задается параметрами
```
--keep-within=30d
--keep-monthly=2
```
Помещаем скрипт в cron с перенаправлением вывода в лог
```
[root@server ~]# crontab -l
45 * * * * /root/backup-data.sh >> /var/log/borg.log 2>&1
```
Смотрим лог
```
[root@server ~]# cat /var/log/borg.log
files-etc
------------------------------------------------------------------------------  
Archive name: etc-2020-06-23_03:45:02
Archive fingerprint: 8ea3f1ffd00c7df5195d761ebf275ba733cdea4b4a5469ad129643e6be5593e5
Time (start): Tue, 2020-06-23 03:45:04
Time (end):   Tue, 2020-06-23 03:45:05
Duration: 0.70 seconds
Number of files: 1698
Utilization of max. archive size: 0%
------------------------------------------------------------------------------
                       Original size      Compressed size    Deduplicated size
This archive:               28.43 MB             13.49 MB             31.22 kB
All archives:               85.28 MB             40.47 MB             11.87 MB

                       Unique chunks         Total chunks
Chunk index:                    1283                 5085
------------------------------------------------------------------------------
```
Восстанавливаем из последнего бэкапа
```
[root@server ~]# mkdir /tmp/etc

[root@server ~]# borg list root@backup:files-etc
etc-2020-06-23_03:37:06              Tue, 2020-06-23 03:37:08 [ecd767b76d3cface31e75d460e7f67433a832139c0bb0026cb86ccd801a0e791]
etc-2020-06-23_03:39:20              Tue, 2020-06-23 03:39:24 [f3d4e4b55ed7de45c28357aeadcee17fe546427ea4e6aae84b63f4d9e5736c4c]
etc-2020-06-23_03:45:02              Tue, 2020-06-23 03:45:04 [8ea3f1ffd00c7df5195d761ebf275ba733cdea4b4a5469ad129643e6be5593e5]

[root@server ~]# borg mount root@backup:files-etc::etc-2020-06-23_03:45:02 /tmp/etc

[root@server ~]# ls /tmp/etc
etc

[root@server ~]# borg umount /tmp/etc
```
