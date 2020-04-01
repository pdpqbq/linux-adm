### Создать свой RPM

Нам понадобятся следующие пакеты:
```
[vagrant@localhost ~]$ sudo yum install -y \
rpmdevtools \
rpm-build \
createrepo \
yum-utils
```
Для создания RPM возьмем скрипт из ДЗ №5 - [ps.sh](https://github.com/pdpqbq/linux-adm/blob/master/5_processes/ps.sh)

Создаем структуру каталогов
```
[vagrant@localhost ~]$ rpmdev-setuptree
[vagrant@localhost ~]$ ls *
BUILD  RPMS  SOURCES  SPECS  SRPMS
```
Размещаем скрипт в каталоге - rpms/SOURCES/myps.sh

Создаем файл rpms/SPECS/myps.spec с таким содержанием
```
Summary:   'ps ax' in bash
Name:      myps
Version:   0.1
Release:   1
License:   GPL
Group:     None
BuildArch: noarch
Source0:   %{name}.sh
Requires:  bash

%description
bash version of 'ps ax'

%install
install -m 755 -d %{buildroot}/opt/myps.sh

%files
/opt/myps.sh
```
Также возможно создать шаблон spec-файла, и далее его редактировать
```
cd rpms/SOURCES/
rpmdev-newspec myps.sh
```
Запускаем
```
rpmbuild -bb rpms/SPECS/myps.spec
```
И получаем файл пакета rpms/RPMS/noarch/myps-0.1-1.noarch.rpm
