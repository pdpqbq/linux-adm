### Установка почтового сервера

1. Установить в виртуалке postfix+dovecot для приёма почты на виртуальный домен
2. Отправить почту телнетом с хоста на виртуалку
3. Принять почту на хост почтовым клиентом

Результат
1. Полученное письмо со всеми заголовками
2. Конфиги postfix и dovecot

Настройка сервера
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
```
/etc/postfix/master.cf
```
dovecot unix - n n - - pipe
  flags=DRhu user=vmail:vmail argv=/usr/lib/dovecot/deliver -f ${sender} -d $(recipient)
```
/etc/dovecot/dovecot.conf
```
protocols = pop3 pop3s
mail_location = maildir:~/Maildir
```
Создание почтовых папок для пользователей, chmod 777 - только для тестов
```
adduser user1
adduser user2
echo user1:test | chpasswd
echo user2:test | chpasswd
mkdir /home/user1/Maildir /home/user2/Maildir
chown user1:user1 /home/user1/Maildir
chown user2:user2 /home/user2/Maildir
chmod -R 777 /home/user1/Maildir
chmod -R 777 /home/user2/Maildir
```
Отправка письма с хоста телнетом:
```
$ telnet 192.168.33.10 25
Trying 192.168.33.10...
Connected to 192.168.33.10.
Escape character is '^]'.
220 mail.local.lan ESMTP Postfix
EHLO mail.local.lan
250-mail.local.lan
250-PIPELINING
250-SIZE 10240000
250-VRFY
250-ETRN
250-ENHANCEDSTATUSCODES
250-8BITMIME
250 DSN
mail from: user2
250 2.1.0 Ok
rcpt to: user1
250 2.1.5 Ok
data
354 End data with <CR><LF>.<CR><LF>
from: user2
to: user1
subject: test3

hi
.
250 2.0.0 Ok: queued as 0D8134080DAD
quit
221 2.0.0 Bye
Connection closed by foreign host.
```
Получение почты на хосте почтовым клиентом, исходный текст письма:
```
From - Fri Jun 26 15:52:58 2020
X-Account-Key: account1
X-UIDL: 000000015ef5ef19
X-Mozilla-Status: 0001
X-Mozilla-Status2: 00000000
X-Mozilla-Keys:                                                                                 
Return-Path: <user2@local.lan>
X-Original-To: user1
Delivered-To: user1@local.lan
Received: from mail.local.lan (unknown [192.168.33.1])
	by mail.local.lan (Postfix) with ESMTP id 0D8134080DAD
	for <user1>; Fri, 26 Jun 2020 12:52:05 +0000 (UTC)
from: user2
to: user1
subject: test3

hi
```
### Литература
- [Postfix HOWTO](https://wiki.centos.org/HowTos/postfix)
