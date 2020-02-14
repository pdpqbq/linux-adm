### Обновление ядра по методичке
Результат опубликован на vagrant cloud. Vagrant-файл опубликован в репозиторий.

### Обновление ядра из исходников

###### Установка необходимых пакетов
```
sudo yum groupinstall -y "Development Tools"
sudo yum install -y ncurses-devel
sudo yum install qt3-devel # для графического режима
sudo yum install -y hmaccalc zlib-devel binutils-devel elfutils-libelf-devel wget openssl-devel bc
```
###### Скачивание и распаковка исходников ядра
```
cd /usr/src/kernels
sudo wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.5.1.tar.xz && \
sudo tar xvf linux-5.5.1.tar.xz && sudo rm linux-5.5.1.tar.xz
cd linux-5.5.1
```
###### Конфигурация
```
cp /boot/config-`uname -r` .config
sudo make oldconfig
sudo make menuconfig
```
###### Сборка
```
sudo make && sudo make modules
```
###### Установка
```
sudo make install && sudo make modules_install
```
###### Настройка параметров загрузчика
```
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo grub2-set-default 0
```
###### Перезагрузка
```
sudo reboot
```
