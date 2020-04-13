#!/bin/bash

### enable audit (w - write) on nginx logs

# auditctl -w /etc/nginx/nginx.conf -p w -k watch_nginx_conf
# auditctl -w /etc/nginx/conf.d/ -p w -k watch_nginx_conf
echo "## enable audit (w - write) on nginx logs" >> /etc/audit/rules.d/audit.rules
echo -w /etc/nginx/nginx.conf -p w -k watch_nginx_conf >> /etc/audit/rules.d/audit.rules
echo -w /etc/nginx/conf.d/ -p w -k watch_nginx_conf >> /etc/audit/rules.d/audit.rules

### enable audit log to remote

sed -i 's/active = no/active = yes/' /etc/audisp/plugins.d/au-remote.conf
sed -i 's/remote_server =/remote_server = 192\.168\.33\.20/' /etc/audisp/audisp-remote.conf
sed -i 's/network_failure_action = stop/network_failure_action = ignore/' /etc/audisp/audisp-remote.conf

### enable local storage for systemd journal with maxlevel=warning

sed -i 's/#MaxLevelStore=.*/MaxLevelStore=warning/' /etc/systemd/journald.conf
sed -i 's/#Storage=auto/Storage=persistent/' /etc/systemd/journald.conf
sed -i '/WatchdogSec/a Restart=on-failure' /usr/lib/systemd/system/systemd-journal-upload.service

### setup journald rotation, size 1G, time 1hr

sed -i 's/#SystemMaxUse=.*/SystemMaxUse=1G/' /etc/systemd/journald.conf
sed -i 's/#MaxRetentionSec=.*/MaxRetentionSec=3600/' /etc/systemd/journald.conf

### logrotate nginx logs

# /etc/logrotate.d/nginx
# /etc/logrotate.conf
(crontab -l; echo "1 * * * * /sbin/logrotate /etc/logrotate.d/nginx") | crontab

### set remote host for journal upload

sed -i 's/# URL=/URL=http:\/\/192\.168\.33\.20:19532/' /etc/systemd/journal-upload.conf

### add nginx access log destination, error log to local syslog

sed -i '/access_log/a\    access_log  syslog:server=192.168.33.20:514,facility=local7,tag=nginx_access,severity=info main;' /etc/nginx/nginx.conf
sed -i '/error_log/a error_log syslog:server=unix:/dev/log,facility=local7,tag=nginx_error,severity=error;' /etc/nginx/nginx.conf

### create log generator service

cat > /opt/loggen.sh << \EOF
#! /bin/bash
# "emerg" (0), "alert" (1), "crit" (2), "err" (3), "warning" (4), "notice" (5), "info" (6), "debug" (7)
logger ALERT MESSAGE -t web-loggen -p 1
logger CRITICAL MESSAGE -t web-loggen -p 2
logger ERROR MESSAGE -t web-loggen -p 3
logger WARNING MESSAGE -t web-loggen -p 4
logger NOTICE MESSAGE -t web-loggen -p 5
curl -s http://localhost:80/index.html > /dev/null
curl -s http://localhost:80/1 > /dev/null
touch /etc/nginx/nginx.conf
exit 0
EOF

chmod +x /opt/loggen.sh

cat > /etc/systemd/system/loggen.service << \EOF
[Unit]
Description=Log Generator
After=systemd-journal-upload.service
[Service]
ExecStart=/opt/loggen.sh
Restart=on-success
RestartSec=42
[Install]
WantedBy=multi-user.target
EOF

### restart

systemctl enable loggen.service
systemctl enable systemd-journal-upload
systemctl enable systemd-journald
#service auditd restart
#systemctl restart loggen.service
#systemctl restart systemd-journal-upload
#systemctl restart systemd-journald
