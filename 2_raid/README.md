### Добавить в Vagrantfile еще дисков

Vagrantfile с дисками собирает raid6 при запуске

Также скрипты для сборки выделены в отдельные файлы

### Собрать R6
```
mdadm --zero-superblock --force /dev/sd{b,c,d,e,f,g,h}

Можно игнорировать, mdadm говорит что не знает про рейд на этих дисках
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
mdadm: Unrecognised md component device - /dev/sdf

mdadm --create --verbose /dev/md0 -l 6 -n 5 /dev/sd{b,c,d,e,f}
```
### Расширить массив
```
mdadm /dev/md0 --add /dev/sdg
mdadm --detail /dev/md0
mdadm --grow /dev/md0 --raid-devices=6
```
### Добавить spare диск
```
mdadm /dev/md0 --add /dev/sdh
```
### Сломать/починить raid
```
mdadm /dev/md0 --fail /dev/sdd

cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid6 sdh[6] sdg[5] sdf[4] sde[3] sdd[2](F) sdc[1] sdb[0]
      1015808 blocks super 1.2 level 6, 512k chunk, algorithm 2 [6/5] [UU_UUU]
      [======>..............]  recovery = 32.5% (83200/253952) finish=0.1min speed=27733K/sec
      
unused devices: <none>

mdadm /dev/md0 --fail /dev/sdc

cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid6 sdh[6] sdg[5] sdf[4] sde[3] sdd[2](F) sdc[1](F) sdb[0]
      1015808 blocks super 1.2 level 6, 512k chunk, algorithm 2 [6/5] [U_UUUU]
      
unused devices: <none>

mdadm --detail /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Mon Feb 17 19:36:17 2020
        Raid Level : raid6
        Array Size : 1015808 (992.00 MiB 1040.19 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 6
     Total Devices : 7
       Persistence : Superblock is persistent

       Update Time : Mon Feb 17 19:47:34 2020
             State : clean, degraded 
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 2
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : otuslinux:0  (local to host otuslinux)
              UUID : 38115cae:9d68ceac:894c70e3:1b42c034
            Events : 67

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       -       0        0        1      removed
       6       8      112        2      active sync   /dev/sdh
       3       8       64        3      active sync   /dev/sde
       4       8       80        4      active sync   /dev/sdf
       5       8       96        5      active sync   /dev/sdg

       1       8       32        -      faulty   /dev/sdc
       2       8       48        -      faulty   /dev/sdd

mdadm /dev/md0 --remove /dev/sdc
mdadm: hot removed /dev/sdc from /dev/md0

mdadm /dev/md0 --remove /dev/sdd
mdadm: hot removed /dev/sdd from /dev/md0

mdadm /dev/md0 --add /dev/sdc

mdadm --detail /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Mon Feb 17 19:36:17 2020
        Raid Level : raid6
        Array Size : 1015808 (992.00 MiB 1040.19 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 6
     Total Devices : 6
       Persistence : Superblock is persistent

       Update Time : Mon Feb 17 19:52:37 2020
             State : clean, degraded, recovering 
    Active Devices : 5
   Working Devices : 6
    Failed Devices : 0
     Spare Devices : 1

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

    Rebuild Status : 57% complete

              Name : otuslinux:0  (local to host otuslinux)
              UUID : 38115cae:9d68ceac:894c70e3:1b42c034
            Events : 80

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       7       8       32        1      spare rebuilding   /dev/sdc
       6       8      112        2      active sync   /dev/sdh
       3       8       64        3      active sync   /dev/sde
       4       8       80        4      active sync   /dev/sdf
       5       8       96        5      active sync   /dev/sdg


mdadm /dev/md0 --add /dev/sdd (spare диск)
```
### Прописать собранный рейд в конф, чтобы рейд собирался при загрузке
```
echo "DEVICE partitions" > /etc/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm.conf
```
### Создать GPT раздел и 5 партиций
```
parted -s /dev/sdc mklabel gpt
parted /dev/sdc mkpart primary ext4 0% 20%
parted /dev/sdc mkpart primary ext4 20% 40%
parted /dev/sdc mkpart primary ext4 40% 60%
parted /dev/sdc mkpart primary ext4 60% 80%
parted /dev/sdc mkpart primary ext4 80% 100%

for i in $(seq 1 5); do sudo mkfs.ext4 /dev/sdc$i; done
mkdir -p /hdd3/part{1,2,3,4,5}
for i in $(seq 1 5); do mount /dev/sdc$i /hdd3/part$i; done

parted -l

Model: ATA VBOX HARDDISK (scsi)
Disk /dev/sdc: 1074MB
Sector size (logical/physical): 512B/512B
Partition Table: gpt
Disk Flags: 

Number  Start   End     Size   File system  Name     Flags
 1      1049kB  215MB   214MB  ext4         primary
 2      215MB   430MB   215MB  ext4         primary
 3      430MB   644MB   214MB  ext4         primary
 4      644MB   859MB   215MB  ext4         primary
 5      859MB   1073MB  214MB  ext4         primary
 ```
