#!/bin/bash

# setup journal-remote reciever

mkdir -p /var/log/journal/remote
chown systemd-journal-remote:systemd-journal-remote /var/log/journal/remote
sed -i 's/#Storage=auto/Storage=persistent/' /etc/systemd/journald.conf
sed -i 's/listen-https/listen-http/' /usr/lib/systemd/system/systemd-journal-remote.service
# /etc/systemd/system/systemd-journal-remote.service.d/override.conf

# set journald max size

sed -i 's/#SystemMaxUse=.*/SystemMaxUse=10G/' /etc/systemd/journald.conf

# enable rsyslog network listener

sed -i 's/#$ModLoad imudp/$ModLoad imudp/' /etc/rsyslog.conf
sed -i 's/#$UDPServerRun 514/$UDPServerRun 514/' /etc/rsyslog.conf
sed -i 's/#$ModLoad imtcp/$ModLoad imtcp/' /etc/rsyslog.conf
sed -i 's/#$InputTCPServerRun 514/$InputTCPServerRun 514/' /etc/rsyslog.conf

# enable auditd reciever

sed -i 's/##tcp_listen_port = 60/tcp_listen_port = 60/' /etc/audit/auditd.conf
sed -i 's/tcp_listen_queue =.*/tcp_listen_queue = 10/' /etc/audit/auditd.conf
sed -i 's/tcp_max_per_addr =.*/tcp_max_per_addr = 4/' /etc/audit/auditd.conf

# rsyslog processing rule for nginx access log

cat > /etc/rsyslog.d/nginx.conf << \EOF
if $syslogfacility-text == 'local7' and $programname == 'nginx_access' then /var/log/nginx_remote/access.log # if true then write to file
&~ # and stop processing
EOF

# restart

service auditd restart
systemctl enable rsyslog
systemctl enable systemd-journal-remote
systemctl restart rsyslog
systemctl restart systemd-journal-remote
