
### Запретить всем пользователям, кроме группы admin, логин в выходные (суббота и воскресенье), без учета праздников

Создаем пользователей и включаем вход по паролю
```
useradd adminuser
useradd notadminuser
echo "1" | passwd --stdin adminuser
echo "1" | passwd --stdin notadminuser
groupadd admin
gpasswd -a adminuser admin # -a add, -d delete
gpasswd -a vagrant admin # -a add, -d delete
bash -c "sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config && systemctl restart sshd.service"
```
Создаем скрипт, который проверяет номер дня недели и группу. Если день недели ПН-ПТ или логин в группе admin - скрипт возвращает 0, иначе 1
```
cat > /usr/local/bin/test_login.sh << \EOF
#!/bin/bash
(( `date +%u` < 6 )) || id $PAM_USER | grep "(admin)"
EOF

chmod +x /usr/local/bin/test_login.sh
```
Добавляем проверку в файлах /etc/pam.d/sshd и /etc/pam.d/login (нужно добавить в начало файла)
```
account    required     pam_exec.so /usr/local/bin/test_login.sh
```
### Дать конкретному пользователю права работать с докером

Добавим пользователя в файл sudoers, чтобы он мог запускать докер с правами root без ввода пароля
```
visudo
notadminuser ALL = (root) NOPASSWD: /bin/docker
notadminuser ALL = (root) NOPASSWD: /bin/systemctl restart docker
```
Проверка
```
[notadminuser@localhost]$ sudo systemctl restart docker
[notadminuser@localhost]$ docker
```
### Запуск стенда

Настройка стенда проводится через ansible
