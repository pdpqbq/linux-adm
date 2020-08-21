#!/bin/bash

fname=mysql--`date +%Y_%m_%d--%H_%M_%S`
xtrabackup --backup --target-dir=/data/backups/$fname
xtrabackup --prepare --target-dir=/data/backups/$fname
tar czf /data/backups/$fname.tar.gz /data/backups/$fname
rm -rf /data/backups/$fname
scp /data/backups/$fname.tar.gz root@192.168.100.20:/root/$fname.tar.gz
