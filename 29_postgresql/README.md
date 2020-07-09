### PostgreSQL

- Настроить hot_standby репликацию с использованием слотов
- Настроить правильное резервное копирование

Установка PostgreSQL 12

https://www.postgresql.org/download/linux/redhat/
```
yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
yum install postgresql12-server
/usr/pgsql-12/bin/postgresql-12-setup initdb
systemctl enable --now postgresql-12
```
Настраиваем разрешения для соединений в файле /var/lib/pgsql/12/data/pg_hba.conf
```
local   all             all                                       peer
host    all             all               127.0.0.1/32            ident
host    all             postgres          192.168.33.0/24         md5
host    postgres        barman            192.168.33.0/24         md5
host    replication     replicator        192.168.33.20/32        md5
host    replication     streaming_barman  192.168.33.20/32        md5
```
Создаем пользователей, базу, слот, наполняем таблицу скриптом master.sql

Устанавливаем параметр listen_addresses = '*'

На standby запускаем репликацию через слот, перед этим очищаем каталог с базой
```
rm -rf /var/lib/pgsql/12/data/*
su postgres -c "pg_basebackup -h 192.168.33.10 -U replicator -p 5432 -D {{ pgdata }} -Fp -Xs -P -R -S slot1"
```
Параметр -R создает необходимые настройки в postgres.auto.conf и файл standby.signal

A replication slave will run in “Hot Standby” mode if the hot_standby parameter is set to on (the default value) in postgresql.conf and there is a standby.signal file present in the data directory.

Файл recovery.conf в версии PostgreSQL 12 не используется
```
primary_conninfo = 'user=replicator password=postgres host=192.168.33.10 port=5432 sslmode=prefer sslcompression=0 gssencmode=prefer krbsrvname=postgres target_session_attrs=any'
primary_slot_name = 'slot1'
```
Запускаем standby
```
/usr/pgsql-12/bin/pg_ctl -D {{ pgdata }} start
```
Остановим реплику
```
[root@standby ~]# su postgres -c "/usr/pgsql-12/bin/pg_ctl -D /var/lib/pgsql/12/data stop"
```
Выполним несколько раз обновление данных на мастере и посмотрим размер созданных WAL
```
otus=# UPDATE t SET pad = md5(random()::text);

otus=# SELECT redo_lsn, slot_name,restart_lsn,
round((redo_lsn-restart_lsn) / 1024 / 1024 / 1024, 2) AS GB_behind
FROM pg_control_checkpoint(), pg_replication_slots;
  redo_lsn  | slot_name | restart_lsn | gb_behind
------------+-----------+-------------+-----------
 0/9226DD00 | slot1     | 0/15000060  |      1.96
(1 row)
```
Запустим реплику
```
[root@standby ~]# su postgres -c "/usr/pgsql-12/bin/pg_ctl -D /var/lib/pgsql/12/data start"
```
Репликация прошла, размер логов уменьшился
```
otus=# SELECT redo_lsn, slot_name,restart_lsn,
round((redo_lsn-restart_lsn) / 1024 / 1024 / 1024, 2) AS GB_behind
FROM pg_control_checkpoint(), pg_replication_slots;
  redo_lsn  | slot_name | restart_lsn | gb_behind
------------+-----------+-------------+-----------
 0/9226DD00 | slot1     | 0/97000000  |     -0.08
(1 row)
```
### Barman

Для работы barman установим на мастере в postgresql.conf
```
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
```
Создаём пользователей на мастере для управления и стриминга
```
create user barman with superuser nocreatedb login password 'barman';
create user streaming_barman with login replication password 'barman';
```
Перезапуск для применения изменений
```
psql -c "select pg_reload_conf()"
```
На standby создаём /etc/barman.d/master.conf
```
[master]
description =  "Master PostgreSQL Database (Streaming-Only)"
conninfo = host=192.168.33.10 user=barman dbname=postgres
streaming_conninfo = host=192.168.33.10 user=streaming_barman
backup_method = postgres
streaming_backup_name = barman_streaming_backup
streaming_archiver = on
slot_name = barman
create_slot = auto
streaming_archiver_name = barman_receive_wal
streaming_archiver_batch_size = 50
path_prefix = "/usr/pgsql-12/bin"
retention_policy_mode = auto
retention_policy = RECOVERY WINDOW OF 7 days
wal_retention_policy = main
```
Проверка доступа
```
$ psql -c 'SELECT version()' -U barman -h 192.168.33.10 postgres
                                                 version                                                 
---------------------------------------------------------------------------------------------------------
 PostgreSQL 12.3 on x86_64-pc-linux-gnu, compiled by gcc (GCC) 4.8.5 20150623 (Red Hat 4.8.5-39), 64-bit
(1 row)

$ psql -U streaming_barman -h 192.168.33.10 -c "IDENTIFY_SYSTEM" replication=1
      systemid       | timeline |  xlogpos   | dbname
---------------------+----------+------------+--------
 6846737974915149932 |        1 | 0/3967E760 |
(1 row)
```
Создаем cron job для barman - полный бэкап каждые 3 минуты
```
* * * * * /usr/bin/barman cron
*/3 * * * * /usr/bin/barman backup master --wait
```
Проверка
```
$ barman status master
Server master:
	Description: Master PostgreSQL Database (Streaming-Only)
	Active: True
	Disabled: False
	PostgreSQL version: 12.3
	Cluster state: in production
	pgespresso extension: Not available
	Current data size: 491.0 MiB
	PostgreSQL Data directory: /var/lib/pgsql/12/data
	Current WAL segment: 000000010000000000000096
	Passive node: False
	Retention policies: enforced (mode: auto, retention: RECOVERY WINDOW OF 7 DAYS, WAL retention: MAIN)
	No. of available backups: 0
	First available backup: None
	Last available backup: None
	Minimum redundancy requirements: satisfied (0/0)

$ barman replication-status master
Status of streaming clients for server 'master':
  Current LSN on master: 1/43004DE8
  Number of streaming clients: 3

  1. Async standby
     Application name: walreceiver
     Sync stage      : 5/5 Hot standby (max)
     Communication   : TCP/IP
     IP Address      : 192.168.33.20 / Port: 47220 / Host: -
     User name       : replicator
     Current state   : streaming (async)
     Replication slot: slot1
     WAL sender PID  : 5997
     Started at      : 2020-07-09 00:35:58.103850+00:00
     Sent LSN   : 1/43004DE8 (diff: 0 B)
     Write LSN  : 1/43004DE8 (diff: 0 B)
     Flush LSN  : 1/43004DE8 (diff: 0 B)
     Replay LSN : 1/43004DE8 (diff: 0 B)

  2. Async WAL streamer
     Application name: barman_receive_wal
     Sync stage      : 3/3 Remote write
     Communication   : TCP/IP
     IP Address      : 192.168.33.20 / Port: 47230 / Host: -
     User name       : streaming_barman
     Current state   : streaming (async)
     Replication slot: barman
     WAL sender PID  : 6003
     Started at      : 2020-07-09 00:36:02.917137+00:00
     Sent LSN   : 1/43004DE8 (diff: 0 B)
     Write LSN  : 1/43004DE8 (diff: 0 B)
     Flush LSN  : 1/43000000 (diff: -19.5 KiB)

  3. Async WAL streamer
     Application name: barman_streaming_backup
     Sync stage      : 1/3 1-safe
     Communication   : TCP/IP
     IP Address      : 192.168.33.20 / Port: 47264 / Host: -
     User name       : streaming_barman
     Current state   : backup (async)
     WAL sender PID  : 27770
     Started at      : 2020-07-09 00:45:02.569886+00:00

$ barman check master
Server master:
	PostgreSQL: OK
	is_superuser: OK
	PostgreSQL streaming: OK
	wal_level: OK
	replication slot: OK
	directories: OK
	retention policy settings: OK
	backup maximum age: OK (no last_backup_maximum_age provided)
	compression settings: OK
	failed backups: OK (there are 0 failed backups)
	minimum redundancy requirements: OK (have 1 backups, expected at least 0)
	pg_basebackup: OK
	pg_basebackup compatible: OK
	pg_basebackup supports tablespaces mapping: OK
	systemid coherence: OK
	pg_receivexlog: OK
	pg_receivexlog compatible: OK
	receive-wal running: OK
	archiver errors: OK

$ barman list-backup master
master 20200709T004802 - Thu Jul  9 00:48:16 2020 - Size: 966.4 MiB - WAL Size: 0 B - WAITING_FOR_WALS
master 20200709T004502 - Thu Jul  9 00:47:44 2020 - Size: 966.4 MiB - WAL Size: 32.0 MiB
master 20200709T004204 - Thu Jul  9 00:43:09 2020 - Size: 1.5 GiB - WAL Size: 560.0 MiB

$ barman recover master 20200709T004502 /tmp/data
Starting local restore for server master using backup 20200709T004502
Destination directory: /tmp/data
Copying the base backup.
Copying required WAL segments.
Generating archive status files
Identify dangerous settings in destination directory.

Recovery completed
```
При первом запуске в логе может появиться ошибка, она исправляется переключением wal-файла
```
barman.wal_archiver INFO: No xlog segments found from streaming for master.
barman.server ERROR: Check 'WAL archive' failed for server 'master'
-bash-4.2$ barman check master
Server master:
	WAL archive: FAILED (please make sure WAL shipping is setup)

$ barman switch-wal --force master'
```
https://www.percona.com/blog/2019/10/11/how-to-set-up-streaming-replication-in-postgresql-12/

https://www.percona.com/blog/2018/11/30/postgresql-streaming-physical-replication-with-slots/

https://severalnines.com/blog/using-barman-backup-postgresql-overview
