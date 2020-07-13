### MySQL

Развернуть базу из дампа и настроить репликацию  
Базовый стенд взят отсюда https://gitlab.com/otus_linux/stands-mysql  

Установка
```
yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
yum install Percona-Server-server-57
```
Основной конфиг в /etc/my.cnf, дополнительные конфиги в /etc/my.cnf.d/

Стенд поднимается с готовыми конфигами из каталога conf/{master,slave}, сервис mysql запущен  
Для перемещения дампа подключим через nfs каталог /tmp на слейве к мастеру /mnt/nfs_share  
Различия в параметрах:
```
server-id = 1 # master
server-id = 2 # slave

# Эта часть только для слэйва - исключаем репликацию таблиц
replicate-ignore-table=bet.events_on_demand
replicate-ignore-table=bet.v_same_event

# Этот параметр добавлен к базовому стенду
binlog_do_db = bet
```
При установке Percona автоматически генерирует пароль для пользователя root и кладет его в файл /var/log/mysqld.log
```
[root@master ~]# cat /var/log/mysqld.log | grep 'root@localhost:' | awk '{print $11}'
Bned9G<VprsW
```
Подключаемся к mysql и меняем пароль для доступа к полному функционалу
```
[root@master ~]# mysql -uroot -p'Bned9G<VprsW'
mysql> ALTER USER USER() IDENTIFIED BY 'Aaaa_1111';
```
Репликацию будем настраивать с использованием GTID. Следует обратить внимание, что атрибут server-id на мастер-сервере должен обязательно отличаться от server-id слейв-сервера
```
mysql> SELECT @@server_id;
+-------------+
| @@server_id |
+-------------+
|           1 |
+-------------+
```
Убеждаемся что GTID включен
```
mysql> SHOW VARIABLES LIKE 'gtid_mode';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| gtid_mode     | ON    |
+---------------+-------+
```
Создадим тестовую базу bet и загрузим в нее дамп и проверим
```
mysql> create database bet;

[root@master ~]# mysql -uroot -p -D bet < /vagrant/bet.dmp

mysql> USE BET;
mysql> SHOW TABLES;
+------------------+
| Tables_in_bet    |
+------------------+
| bookmaker        |
| competition      |
| events_on_demand |
| market           |
| odds             |
| outcome          |
| v_same_event     |
+------------------+
```
Создадим пользователя для репликации и даем ему права
```
mysql> GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%' IDENTIFIED BY '!OtusLinux2018';

mysql> SELECT user,host FROM mysql.user where user='repl';
+------+------+
| user | host |
+------+------+
| repl | %    |
+------+------+
```
Перед созданием дампа устанавливаем режим только для чтения, получаем текущую позицию лога
```
mysql> FLUSH TABLES WITH READ LOCK;
mysql> SET GLOBAL READ_ONLY = ON;
mysql> SHOW MASTER STATUS;
+------------------+----------+--------------+------------------+-------------------------------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set                         |
+------------------+----------+--------------+------------------+-------------------------------------------+
| mysql-bin.000002 |   119320 | bet          |                  | e225e8a7-c54b-11ea-a7e7-5254004d77d3:1-38 |
+------------------+----------+--------------+------------------+-------------------------------------------+
```
Дампим базу на slave и игнорируем таблицы по заданию
```
[root@master ~]# mysqldump --all-databases --triggers --routines --master-data --ignore-table=bet.events_on_demand --ignore-table=bet.v_same_event -uroot -p > /mnt/nfs_share/master.sql
```
На этом настройка master-а завершена

Заходим на слейв
```
[root@slave ~]# cat /var/log/mysqld.log | grep 'root@localhost:' | awk '{print $11}'
gzpi()1ipj2P

[root@slave ~]# mysql -uroot -p'gzpi()1ipj2P

mysql> ALTER USER USER() IDENTIFIED BY 'Aaaa_1111';

mysql> SELECT @@server_id;
+-------------+
| @@server_id |
+-------------+
|           2 |
+-------------+

mysql> SHOW VARIABLES LIKE 'gtid_mode';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| gtid_mode     | ON    |
+---------------+-------+

mysql> SOURCE /tmp/master.sql

mysql> SHOW DATABASES LIKE 'bet';
+----------------+
| Database (bet) |
+----------------+
| bet            |
+----------------+

mysql> USE bet;

mysql> SHOW TABLES;
+---------------+
| Tables_in_bet | # видим что таблиц v_same_event и events_on_demand нет
+---------------+
| bookmaker     |
| competition   |
| market        |
| odds          |
| outcome       |
+---------------+
```
Подключаем и запускаем слейв. Значение MASTER_LOG_POS = 119320 берем с мастера  
При запуске с параметром MASTER_AUTO_POSITION = 1 на слейве возникали различные ошибки
```
mysql> CHANGE MASTER TO MASTER_HOST = "192.168.11.150", MASTER_PORT = 3306, MASTER_USER = "repl", MASTER_PASSWORD = "!OtusLinux2018", MASTER_LOG_POS = 119320;

mysql> START SLAVE;

mysql> SHOW SLAVE STATUS\G
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.11.150
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000002
          Read_Master_Log_Pos: 119320
               Relay_Log_File: slave-relay-bin.000002
                Relay_Log_Pos: 320
        Relay_Master_Log_File: mysql-bin.000002
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table: bet.events_on_demand,bet.v_same_event
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 119320
              Relay_Log_Space: 527
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 1
                  Master_UUID: e225e8a7-c54b-11ea-a7e7-5254004d77d3
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set: 25a70c9d-c54e-11ea-89be-5254004d77d3:1
                Auto_Position: 0
         Replicate_Rewrite_DB:
                 Channel_Name:
           Master_TLS_Version:
```
Снимаем блокировку с мастера
```
mysql> UNLOCK TABLES;
mysql> SET GLOBAL READ_ONLY = OFF;
```
Проверим репликацию в действии. Добавим данные на мастере
```
mysql> use bet;

mysql> INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet');

mysql> SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+
```
На слейве
```
mysql> SELECT * FROM bookmaker;
+----+----------------+
| id | bookmaker_name |
+----+----------------+
|  1 | 1xbet          |
|  4 | betway         |
|  5 | bwin           |
|  6 | ladbrokes      |
|  3 | unibet         |
+----+----------------+

mysql> SHOW SLAVE STATUS\G
          Read_Master_Log_Pos: 119616
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
          Exec_Master_Log_Pos: 119616
                  Master_UUID: e225e8a7-c54b-11ea-a7e7-5254004d77d3
           Retrieved_Gtid_Set: e225e8a7-c54b-11ea-a7e7-5254004d77d3:39
            Executed_Gtid_Set: 25a70c9d-c54e-11ea-89be-5254004d77d3:1,
e225e8a7-c54b-11ea-a7e7-5254004d77d3:39

[root@slave mysql]# strings slave-relay-bin.000002
5.7.30-33-log
mysql-bin.000002L
5.7.30-33-log
BEGIN
INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet')I

[root@slave mysql]# mysqlbinlog mysql-bin.000002
/*!50530 SET @@SESSION.PSEUDO_SLAVE_MODE=1*/;
/*!50003 SET @OLD_COMPLETION_TYPE=@@COMPLETION_TYPE,COMPLETION_TYPE=0*/;
DELIMITER /*!*/;
# at 4
#200713 21:16:44 server id 2  end_log_pos 123 CRC32 0xa2fe461d 	Start: binlog v 4, server v 5.7.30-33-log created 200713 21:16:44 at startup
# Warning: this binlog is either in use or was not closed properly.
ROLLBACK/*!*/;
BINLOG '
PM8MXw8CAAAAdwAAAHsAAAABAAQANS43LjMwLTMzLWxvZwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAA8zwxfEzgNAAgAEgAEBAQEEgAAXwAEGggAAAAICAgCAAAACgoKKioAEjQA
AR1G/qI=
'/*!*/;
# at 123
#200713 21:16:44 server id 2  end_log_pos 154 CRC32 0x7ebab871 	Previous-GTIDs
# [empty]
# at 154
#200713 21:19:00 server id 2  end_log_pos 219 CRC32 0xd0511f92 	GTID	last_committed=0	sequence_number=1	rbr_only=no
SET @@SESSION.GTID_NEXT= '25a70c9d-c54e-11ea-89be-5254004d77d3:1'/*!*/;
# at 219
#200713 21:19:00 server id 2  end_log_pos 414 CRC32 0xeba82cea 	Query	thread_id=3	exec_time=0	error_code=0
SET TIMESTAMP=1594675140/*!*/;
SET @@session.pseudo_thread_id=3/*!*/;
SET @@session.foreign_key_checks=1, @@session.sql_auto_is_null=0, @@session.unique_checks=1, @@session.autocommit=1/*!*/;
SET @@session.sql_mode=1436549152/*!*/;
SET @@session.auto_increment_increment=1, @@session.auto_increment_offset=1/*!*/;
/*!\C utf8 *//*!*/;
SET @@session.character_set_client=33,@@session.collation_connection=33,@@session.collation_server=8/*!*/;
SET @@session.lc_time_names=0/*!*/;
SET @@session.collation_database=DEFAULT/*!*/;
ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' AS '*1ADB4888D426B440777F3B4089E5C5DDFC5235C0'
/*!*/;
# at 414
#200713 21:31:44 server id 1  end_log_pos 479 CRC32 0xbb53cd23 	GTID	last_committed=1	sequence_number=2	rbr_only=no
SET @@SESSION.GTID_NEXT= 'e225e8a7-c54b-11ea-a7e7-5254004d77d3:39'/*!*/;
# at 479
#200713 21:31:44 server id 1  end_log_pos 552 CRC32 0xc632d6f8 	Query	thread_id=11	exec_time=0	error_code=0
SET TIMESTAMP=1594675904/*!*/;
BEGIN
/*!*/;
# at 552
#200713 21:31:44 server id 1  end_log_pos 679 CRC32 0x44bf5b57 	Query	thread_id=11	exec_time=0	error_code=0
use `bet`/*!*/;
SET TIMESTAMP=1594675904/*!*/;
INSERT INTO bookmaker (id,bookmaker_name) VALUES(1,'1xbet')
/*!*/;
# at 679
#200713 21:31:44 server id 1  end_log_pos 710 CRC32 0xb2f45fbd 	Xid = 421
COMMIT/*!*/;
SET @@SESSION.GTID_NEXT= 'AUTOMATIC' /* added by mysqlbinlog */ /*!*/;
DELIMITER ;
# End of log file
/*!50003 SET COMPLETION_TYPE=@OLD_COMPLETION_TYPE*/;
/*!50530 SET @@SESSION.PSEUDO_SLAVE_MODE=0*/;
```
