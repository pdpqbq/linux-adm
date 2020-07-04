### Установка почтового сервера

1. Установить в виртуалке postfix+dovecot для приёма почты на виртуальный домен
2. Отправить почту телнетом с хоста на виртуалку
3. Принять почту на хост почтовым клиентом

Результат
1. Полученное письмо со всеми заголовками
2. Конфиги postfix и dovecot

Настройка сервера с виртуальным доменом example.com и пользователями user3, user4
```
hostnamectl set-hostname mail.local.lan
```
/etc/postfix/main.cf
```
myhostname = mail.local.lan
mydomain = local.lan
myorigin = $mydomain
inet_interfaces = all
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
mynetworks = 192.168.33.0/24, 127.0.0.0/8
relay_domains =
home_mailbox = Maildir/
# virtual mailboxes
virtual_mailbox_domains = example.com
virtual_mailbox_base = /var/mail/vhosts
virtual_mailbox_maps = hash:/etc/postfix/vmailbox
virtual_minimum_uid = 1000
virtual_uid_maps = static:5000 # uid of vmail user
virtual_gid_maps = static:5000 # gid of vmail user
```
/etc/postfix/vmailbox, "/" в конце строки нужен для создания каталогов
```
user3@example.com   example.com/user3/
user4@example.com   example.com/user4/
```
/etc/postfix/master.cf
```
dovecot unix - n n - - pipe
  flags=DRhu user=vmail:vmail argv=/usr/lib/dovecot/deliver -f ${sender} -d $(recipient)
```
/etc/dovecot/dovecot.conf
```
protocols = imap pop3

# It's nice to have separate log files for Dovecot. You could do this
# by changing syslog configuration also, but this is easier.
log_path = /var/log/dovecot.log
info_log_path = /var/log/dovecot-info.log

# Disable SSL for now.
ssl = no
disable_plaintext_auth = no

# We're using Maildir format
#mail_location = maildir:~/Maildir

# postfix puts mail here
mail_location = maildir:~/

# If you're using POP3, you'll need this:
pop3_uidl_format = %g

# Authentication configuration:
auth_verbose = yes
auth_mechanisms = plain
passdb {
  driver = passwd-file
  args = /etc/dovecot/passwd
}
userdb {
  driver = static
  args = uid=vmail gid=vmail home=/var/mail/vhosts/%d/%n
}
```
Файл с виртуальными пользователями /etc/dovecot/passwd
```
user3@example.com:{PLAIN}test
user4@example.com:{PLAIN}test
```
Создание пользователей и почтовых каталогов
```
# canonical domain
adduser user1
adduser user2
echo user1:test | chpasswd
echo user2:test | chpasswd
mkdir /home/user1/Maildir /home/user2/Maildir
chown user1:user1 /home/user1/Maildir
chown user2:user2 /home/user2/Maildir
chmod -R 775 /home/user1/Maildir
chmod -R 775 /home/user2/Maildir
# hosted domain
groupadd -g 5000 vmail
useradd -u 5000 -g vmail -s /sbin/nologin -d /home/vmail -m vmail
usermod -aG vmail postfix
usermod -aG vmail dovecot
mkdir -p /var/mail/vhosts/example.com
chown -R vmail:vmail /var/mail/vhosts
chmod -R 775 /var/mail/vhosts
postmap /etc/postfix/vmailbox
```
Отправка письма с хоста телнетом:
```
$ telnet 192.168.33.10 25
Trying 192.168.33.10...
Connected to 192.168.33.10.
Escape character is '^]'.
220 mail.local.lan ESMTP Postfix
EHLO example.com
250-mail.local.lan
250-PIPELINING
250-SIZE 10240000
250-VRFY
250-ETRN
250-ENHANCEDSTATUSCODES
250-8BITMIME
250 DSN
mail from: user3@example.com
250 2.1.0 Ok
rcpt to: user4@example.com
250 2.1.5 Ok
data
354 End data with <CR><LF>.<CR><LF>
from: user3
to: user4
subject: test

hi
.
250 2.0.0 Ok: queued as 2C5C7406A7CA
quit
221 2.0.0 Bye
Connection closed by foreign host.
```
Получение почты на хосте почтовым клиентом, исходный текст письма:
```
From - Sun Jul  5 00:01:38 2020
X-Account-Key: account3
X-UIDL: 1593896431.V801I6099ef8M459603.mail.local.lan
X-Mozilla-Status: 0001
X-Mozilla-Status2: 00000000
X-Mozilla-Keys:                                                                                 
Return-Path: <user3@example.com>
X-Original-To: user4@example.com
Delivered-To: user4@example.com
Received: from example.com (unknown [192.168.33.1])
	by mail.local.lan (Postfix) with ESMTP id 2C5C7406A7CA
	for <user4@example.com>; Sat,  4 Jul 2020 21:00:03 +0000 (UTC)
from: user3
to: user4
subject: test

hi
```
### Литература
- [Postfix HOWTO](https://wiki.centos.org/HowTos/postfix)
- [Postfix Virtual Domain Hosting Howto](http://www.postfix.org/VIRTUAL_README.html)
- [Simple Virtual User Installation](https://wiki.dovecot.org/HowTo/SimpleVirtualInstall)
