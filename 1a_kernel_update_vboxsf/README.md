### Обновление ядра centos7 из elrepo и настройка virtualbox shared folders

###### Установка Centos7
```
vagrant init centos/7
```
###### Отключение автообновления vbguest addons в vagrantfile
```
config.vbguest.auto_update = false
```
###### Запуск ВМ
```
vagrant up && vagrant ssh
```
###### Установка mainline ядра из репозитория ELRepo
```
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org && \
sudo yum install -y https://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm && \
sudo yum --enablerepo=elrepo-kernel install -y kernel-ml kernel-ml-devel
```
###### Обновление конфигурации загрузчика
```
sudo grub2-mkconfig -o /boot/grub2/grub.cfg && \
sudo grub2-set-default 0
```
###### Перезагрузка для активации нового ядра
```
sudo reboot
```
###### Проверка версии ядра
```
vagrant ssh
uname -r
```
```
5.5.4-1.el7.elrepo.x86_64
```
###### Установка VBoxGuestAdditions из iso
```
cd /tmp
mkdir vb
export KERN_DIR=/usr/src/kernels/`uname -r`
sudo yum --enablerepo=elrepo install -y wget gcc make perl
wget https://download.virtualbox.org/virtualbox/6.1.2/VBoxGuestAdditions_6.1.2.iso
sudo mount -o loop VBoxGuestAdditions_6.1.2.iso vb
sudo vb/VBoxLinuxAdditions.run
sudo umount vb && sudo rm -rf vb
```
###### Сообщение об ошибке можно проигнорировать, модули установлены
```
VirtualBox Guest Additions: Look at /var/log/vboxadd-setup.log to find out what 
went wrong
[vagrant@localhost vb]$ cat /var/log/vboxadd-setup.log
Could not find the X.Org or XFree86 Window System, skipping.

[vagrant@localhost vb]$ lsmod | grep vb
vboxsf                 81920  0 
vboxguest             356352  2 vboxsf
```
###### Очистка перед публикацией образа
```
# Remove temporary files
sudo su -
yum clean all
rm -rf /tmp/*
rm  -f /var/log/wtmp /var/log/btmp
rm -rf /var/cache/* /usr/share/doc/*
rm -rf /var/cache/yum
rm  -f ~/.bash_history
history -c
rm -rf /run/log/journal/*
# Fill zeros all empty space
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY
sync
shutdown now
```
###### Упаковка
```
vagrant package --output c7k5sf.box
```
###### Проверка
```
vagrant box add c7k5sf c7k5sf.box
mkdir test
cp Vagrantfile test
cd test
```
###### Новое имя машины в vagrantfile
```
config.vm.box = "c7k5sf"
```
###### Настройка каталогов для shared folders
```
config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
```
###### Отключение обновлений
```
config.vm.box_check_update = false
```
###### Запуск ВМ
```
vagrant up && vagrant ssh
```
###### Проверка пройдена, публикация
```
vagrant cloud publish --release qpbdqp/c7k5sf 1.0 virtualbox c7k5sf.box
```
