### Состояние ДО
```
$ lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  40G  0 disk 
└─sda1   8:1    0  40G  0 part /
sdb      8:16   0   5G  0 disk 
sdc      8:32   0   5G  0 disk 
```
###### отключаем selinux если включено
```
sestatus
# Open the /etc/selinux/config file and set the SELINUX mod to disabled
```
###### создаем разделы sdb1 sdc1 типа fd
```
parted /dev/sdb mklabel msdos
parted /dev/sdb mkpart primary ext4 0% 100%
parted /dev/sdb set 1 raid on

parted /dev/sdc mklabel msdos
parted /dev/sdc mkpart primary ext4 0% 100%
parted /dev/sdc set 1 raid on

Disk /dev/sdb: 5368 MB, 5368709120 bytes, 10485760 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0xe228a50c

   Device Boot      Start         End      Blocks   Id  System
/dev/sdb1            2048    10485759     5241856   fd  Linux raid autodetect

Disk /dev/sdc: 5368 MB, 5368709120 bytes, 10485760 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0xce81cce1

   Device Boot      Start         End      Blocks   Id  System
/dev/sdc1            2048    10485759     5241856   fd  Linux raid autodetect
```
###### создаем raid1
```
mdadm --zero-superblock --force /dev/sd{b1,c1}
mdadm --create --verbose /dev/md0 -l 1 -n 2 /dev/sd{b1,c1}
mkfs.ext4 /dev/md0
```
###### mdadm.conf - это здесь не нужно
```
echo "DEVICE partitions" > /etc/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm.conf
```
###### копируем ОС на новый том
```
mount /dev/md0 /mnt 
tar clf - / --exclude={/dev,/sys,/proc,/tmp,/run,/mnt,/swapfile,/vagrant} | tar -xf - -C /mnt
mkdir /mnt/proc /mnt/dev /mnt/mnt /mnt/sys /mnt/tmp /mnt/run
```
###### добавляем UUID md0 в fstab и указываем mount /
```
blkid /dev/md0
vi /mnt/etc/fstab
```
###### добавляем параметр в конф загрузчика rd.auto=1 -> /mnt/etc/default/grub (GRUB_CMDLINE_LINUX=...rd.auto=1...)
```
vi /mnt/etc/default/grub
```
```
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys
mount --bind /dev /mnt/dev
chroot /mnt
```
###### добавляем драйвер mdadm в initramfs
```
dracut --mdadmconf --force
```
###### устанавливаем загрузчик
```
grub2-mkconfig -o /boot/grub2/grub.cfg
# должно быть наличие строки insmod mdraid1x или mdraid09
# так же в строке linux16 должен быть указан правильный UUID md0
grep 'insmod mdraid' /boot/grub2/grub.cfg
grep 'linux16' /boot/grub2/grub.cfg
grub2-install /dev/sdb
grub2-install /dev/sdc
```
###### покидаем chroot (ctrl+d)
```
exit
```
```
umount /dev/md0 - говорит что используется, всё равно перезагружаемся
```
###### reboot

### Состояние ПОСЛЕ
```
$ lsblk
NAME    MAJ:MIN RM SIZE RO TYPE  MOUNTPOINT
sda       8:0    0  40G  0 disk  
└─sda1    8:1    0  40G  0 part  
sdb       8:16   0   5G  0 disk  
└─sdb1    8:17   0   5G  0 part  
  └─md0   9:0    0   5G  0 raid1 /
sdc       8:32   0   5G  0 disk  
└─sdc1    8:33   0   5G  0 part  
  └─md0   9:0    0   5G  0 raid1 /
```