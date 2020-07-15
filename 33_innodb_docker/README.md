### InnoDB кластер в docker

Докер сделан по статье https://mysqlrelease.com/2018/03/docker-compose-setup-for-innodb-cluster/

![](https://mysqlrelease.com/wp-content/uploads/2018/03/docker-compose.jpg)

Поднимаем 3 узла mysql 5.7 - mysql-server-1, mysql-server-2, mysql-server-3; еще 2 узла mysql-shell и mysql-router

На mysql-shell запускаем настройку кластера скриптом setupCluster.js и создаем базу скриптом db.sql

На mysql-router бутстрапим первый сервер и открываем наружу порт 6446
```
$ sudo docker-compose up
```
Подключаемся с хоста и проверям
```
$ mysql -h 127.0.0.1 -P 6446 -uroot -p'mysql'

mysql> use otus;

mysql> select * from tab1;
+----+-------+
| id | name  |
+----+-------+
|  1 | petya |
|  2 | vasya |
|  3 | kolya |
+----+-------+

mysql> SELECT * FROM performance_schema.replication_group_members;
+---------------------------+--------------------------------------+--------------+-------------+--------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST  | MEMBER_PORT | MEMBER_STATE |
+---------------------------+--------------------------------------+--------------+-------------+--------------+
| group_replication_applier | 789c972d-c69c-11ea-85ef-0242ac190004 | 14358dd49270 |        3306 | ONLINE       |
| group_replication_applier | 789daec5-c69c-11ea-84aa-0242ac190002 | 3c3a52d169cf |        3306 | ONLINE       |
| group_replication_applier | 793b76cf-c69c-11ea-85d3-0242ac190003 | cf816c88684f |        3306 | ONLINE       |
+---------------------------+--------------------------------------+--------------+-------------+--------------+
```
Подключаемся в mysql-shell - первый сервер RW, второй и третий RO
```
mysql-js> shell.connect('root@mysql-server-1:3306', "mysql")

mysql-js> dba.getCluster().status()
{
    "clusterName": "otusCluster",
    "defaultReplicaSet": {
        "name": "default",
        "primary": "mysql-server-1:3306",
        "status": "OK",
        "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.",
        "topology": {
            "mysql-server-1:3306": {
                "address": "mysql-server-1:3306",
                "mode": "R/W",
                "readReplicas": {},
                "role": "HA",
                "status": "ONLINE"
            },
            "mysql-server-2:3306": {
                "address": "mysql-server-2:3306",
                "mode": "R/O",
                "readReplicas": {},
                "role": "HA",
                "status": "ONLINE"
            },
            "mysql-server-3:3306": {
                "address": "mysql-server-3:3306",
                "mode": "R/O",
                "readReplicas": {},
                "role": "HA",
                "status": "ONLINE"
            }
        }
    }
}
```
Сымитируем сбой первого сервера - третий сервер стал RW
```
$ sudo docker ps | grep server-1
14358dd49270        mysql/mysql-server:5.7       "/entrypoint.sh mysq…"   3 minutes ago       Up 3 minutes (healthy)   33060/tcp, 0.0.0.0:3301->3306/tcp                        33_innodb_docker_mysql-server-1_1

$ sudo docker kill 14358dd49270

mysql-js> shell.connect('root@mysql-server-2:3306', "mysql")

mysql-js> dba.getCluster().status()
WARNING: The session is on a Read Only instance.
         Write operations on the InnoDB cluster will not be allowed

{
    "clusterName": "otusCluster",
    "defaultReplicaSet": {
        "name": "default",
        "primary": "mysql-server-3:3306",
        "status": "OK_NO_TOLERANCE",
        "statusText": "Cluster is NOT tolerant to any failures. 1 member is not active",
        "topology": {
            "mysql-server-1:3306": {
                "address": "mysql-server-1:3306",
                "mode": "R/O",
                "readReplicas": {},
                "role": "HA",
                "status": "(MISSING)"
            },
            "mysql-server-2:3306": {
                "address": "mysql-server-2:3306",
                "mode": "R/O",
                "readReplicas": {},
                "role": "HA",
                "status": "ONLINE"
            },
            "mysql-server-3:3306": {
                "address": "mysql-server-3:3306",
                "mode": "R/W",
                "readReplicas": {},
                "role": "HA",
                "status": "ONLINE"
            }
        }
    }
}

mysql> SELECT * FROM performance_schema.replication_group_members;
+---------------------------+--------------------------------------+--------------+-------------+--------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST  | MEMBER_PORT | MEMBER_STATE |
+---------------------------+--------------------------------------+--------------+-------------+--------------+
| group_replication_applier | 789daec5-c69c-11ea-84aa-0242ac190002 | 3c3a52d169cf |        3306 | ONLINE       |
| group_replication_applier | 793b76cf-c69c-11ea-85d3-0242ac190003 | cf816c88684f |        3306 | ONLINE       |
+---------------------------+--------------------------------------+--------------+-------------+--------------+

mysql> select * from tab1;
+----+-------+
| id | name  |
+----+-------+
|  1 | petya |
|  2 | vasya |
|  3 | kolya |
+----+-------+
```
Запускаем первый сервер
```
$ sudo docker-compose run -d mysql-server-1

mysql-js> shell.connect('root@mysql-server-3:3306', "mysql")

mysql-js> dba.getCluster().addInstance({user: "root", host: "mysql-server-1", password: "mysql"})
The instance 'root@mysql-server-1:3306' was successfully added to the cluster.

mysql-js> dba.getCluster().status()
{
    "clusterName": "otusCluster",
    "defaultReplicaSet": {
        "name": "default",
        "primary": "mysql-server-3:3306",
        "status": "OK",
        "statusText": "Cluster is ONLINE and can tolerate up to ONE failure.",
        "topology": {
            "mysql-server-1:3306": {
                "address": "mysql-server-1:3306",
                "mode": "R/O",
                "readReplicas": {},
                "role": "HA",
                "status": "ONLINE"
            },
            "mysql-server-2:3306": {
                "address": "mysql-server-2:3306",
                "mode": "R/O",
                "readReplicas": {},
                "role": "HA",
                "status": "ONLINE"
            },
            "mysql-server-3:3306": {
                "address": "mysql-server-3:3306",
                "mode": "R/W",
                "readReplicas": {},
                "role": "HA",
                "status": "ONLINE"
            }
        }
    }
}
```
Команды для докера
```
sudo docker inspect
sudo docker run -it --entrypoint /bin/bash mysql-server-1
sudo docker-compose run --entrypoint /bin/bash mysql-shell
```
