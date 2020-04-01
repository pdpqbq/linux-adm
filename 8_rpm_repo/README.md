### Создать свой RPM

Нам понадобятся следующие пакеты:
```
[vagrant@localhost ~]$ sudo yum install -y \
rpmdevtools \
rpm-build \
createrepo \
yum-utils
```
Для создания RPM возьмем скрипт из ДЗ №5 - [ps.sh](https://github.com/pdpqbq/linux-adm/blob/master/5_processes/ps.sh) и назовем его myps.sh

Все действия, кроме yum install, выполняются с правами обычного пользователя

Создаем структуру каталогов
```
[vagrant@localhost ~]$ rpmdev-setuptree
[vagrant@localhost ~]$ ls *
BUILD  RPMS  SOURCES  SPECS  SRPMS
```
Размещаем скрипт в каталоге - rpmbuild/SOURCES/myps.sh

Создаем файл rpmbuild/SPECS/myps.spec с таким содержанием
```
Summary:   'ps ax' in bash
Name:      myps
Version:   0.1
Release:   1
License:   GPL
Group:     None
BuildArch: noarch
Source:    myps.sh
Requires:  bash

%description
bash version of 'ps ax'

%install
install -Dm 755 %{SOURCE0} %{buildroot}/opt/myps.sh

%files
/opt/myps.sh
```
Также возможно создать шаблон spec-файла и отредактировать его
```
cd rpmbuild/SOURCES/
rpmdev-newspec myps
```
Запускаем
```
rpmbuild -bb rpmbuild/SPECS/myps.spec
```
И получаем файл пакета rpmbuild/RPMS/noarch/myps-0.1-1.noarch.rpm

Можно запустить установку
```
[vagrant@localhost ~]$ sudo yum localinstall rpmbuild/RPMS/noarch/myps-0.1-1.noarch.rpm
Examining rpmbuild/RPMS/noarch/myps-0.1-1.noarch.rpm: myps-0.1-1.noarch
Marking rpmbuild/RPMS/noarch/myps-0.1-1.noarch.rpm to be installed
```
После чего в каталоге /opt появится наш скрипт с атрибутами 755
```
[vagrant@localhost ~]$ ll /opt
drwxr-xr-x. myps.sh
```
Удаляем, чтобы перейти к следующему этапу
```
[vagrant@localhost ~]$ sudo yum remove myps
```
### Создать свой репо и разместить там свой RPM

Создаём каталог и копируем в него собранный rpm
```
[root@localhost ~]# mkdir /usr/share/myrepo
[root@localhost ~]# cp /home/vagrant/rpmbuild/RPMS/noarch/myps-0.1-1.noarch.rpm /usr/share/myrepo
```
Инициализируем репозиторий
```
[root@localhost ~]# createrepo /usr/share/myrepo
Spawning worker 0 with 1 pkgs
Workers Finished
Saving Primary metadata
Saving file lists metadata
Saving other metadata
Generating sqlite DBs
Sqlite DBs complete
```
Добавим его в /etc/yum.repos.d
```
[root@localhost ~]# cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=myrepo
baseurl=file:///usr/share/myrepo
gpgcheck=0
enabled=1
EOF
```
Проверка
```
[root@localhost ~]# yum repolist | grep otus
otus                                myrepo                                     1
[root@localhost ~]# yum list | grep otus
myps.noarch                                 0.1-1                      otus     
[root@localhost ~]# yum install myps -y
---> Package myps.noarch 0:0.1-1 will be installed
Complete!
```
