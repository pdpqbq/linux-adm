
### Работа с LVM

- поставить btrfs/zfs - с кешем, снэпшотами - разметить здесь каталог /opt

```
[root@lvm ~]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0    1G  0 disk
```

На sdb создадим lv с btrfs для данных и на sdc оставим место для снэпшота

На sdd, sde сделаем кэш

Создаем pv, vg, lv
```
[root@lvm ~]# pvcreate /dev/sd{b,c,d,e}
  Physical volume "/dev/sdb" successfully created.
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.
  Physical volume "/dev/sde" successfully created.

[root@lvm ~]# vgcreate vg_data /dev/sd{b,c,d,e}
  Volume group "vg_data" successfully created

[root@lvm ~]# lvcreate -l 100%FREE -n lv_data vg_data /dev/sdb
  Logical volume "lv_data" created.

[root@lvm ~]# lvcreate --type cache-pool -l 100%FREE -n cpool vg_data /dev/sdd /dev/sde
  Logical volume "cpool" created.

[root@lvm ~]# lvs -a -o name,size,attr,devices vg_data
  LV              LSize   Attr       Devices
  cpool            <1.98g Cwi---C--- cpool_cdata(0)
  [cpool_cdata]    <1.98g Cwi------- /dev/sde(2)
  [cpool_cdata]    <1.98g Cwi------- /dev/sdd(2)
  [cpool_cmeta]     8.00m ewi------- /dev/sde(0)
  lv_data         <10.00g -wi-a----- /dev/sdb(0)
  [lvol0_pmspare]   8.00m ewi------- /dev/sdd(0)

[root@lvm ~]# lvconvert --type cache --cachepool cpool vg_data/lv_data
Do you want wipe existing metadata of cache pool vg_data/cpool? [y/n]: y
  Logical volume vg_data/lv_data is now cached.

[root@lvm ~]# lvs -a -o name,size,attr,devices vg_data
  LV              LSize   Attr       Devices
  [cpool]          <1.98g Cwi---C--- cpool_cdata(0)
  [cpool_cdata]    <1.98g Cwi-ao---- /dev/sde(2)
  [cpool_cdata]    <1.98g Cwi-ao---- /dev/sdd(2)
  [cpool_cmeta]     8.00m ewi-ao---- /dev/sde(0)
  lv_data         <10.00g Cwi-a-C--- lv_data_corig(0)
  [lv_data_corig] <10.00g owi-aoC--- /dev/sdb(0)
  [lvol0_pmspare]   8.00m ewi------- /dev/sdd(0)

[root@lvm ~]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
└─vg_data-lv_data_corig 253:5    0   10G  0 lvm
  └─vg_data-lv_data     253:2    0   10G  0 lvm
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
└─vg_data-cpool_cdata   253:3    0    2G  0 lvm
  └─vg_data-lv_data     253:2    0   10G  0 lvm
sde                       8:64   0    1G  0 disk
├─vg_data-cpool_cdata   253:3    0    2G  0 lvm
│ └─vg_data-lv_data     253:2    0   10G  0 lvm
└─vg_data-cpool_cmeta   253:4    0    8M  0 lvm
  └─vg_data-lv_data     253:2    0   10G  0 lvm

[root@lvm ~]# mkfs.btrfs /dev/vg_data/lv_data
btrfs-progs v4.9.1
See http://btrfs.wiki.kernel.org for more information.

Performing full device TRIM /dev/vg_data/lv_data (10.00GiB) ...
Label:              (null)
UUID:               04984022-0faf-4d9d-a6b3-ce1eab13975a
Node size:          16384
Sector size:        4096
Filesystem size:    10.00GiB
Block group profiles:
  Data:             single            8.00MiB
  Metadata:         DUP             511.75MiB
  System:           DUP               8.00MiB
SSD detected:       no
Incompat features:  extref, skinny-metadata
Number of devices:  1
Devices:
   ID        SIZE  PATH
    1    10.00GiB  /dev/vg_data/lv_data
```
Монтируем в /opt, создаем снэпшот, удаляем и восстанавливаем данные
```
[root@lvm ~]# mount /dev/vg_data/lv_data /opt

[root@lvm ~]# touch /opt/file{1..100}

[root@lvm ~]# ls /opt
file1    file13  file18  file22  file27  file31  file36  file40  file45  file5   file54  file59  file63  file68  file72  file77  file81  file86  file90  file95
file10   file14  file19  file23  file28  file32  file37  file41  file46  file50  file55  file6   file64  file69  file73  file78  file82  file87  file91  file96
file100  file15  file2   file24  file29  file33  file38  file42  file47  file51  file56  file60  file65  file7   file74  file79  file83  file88  file92  file97
file11   file16  file20  file25  file3   file34  file39  file43  file48  file52  file57  file61  file66  file70  file75  file8   file84  file89  file93  file98
file12   file17  file21  file26  file30  file35  file4   file44  file49  file53  file58  file62  file67  file71  file76  file80  file85  file9   file94  file99

[root@lvm ~]# lvcreate -L 1G -s -n data_snap /dev/vg_data/lv_data
  Logical volume "data_snap" created.

[root@lvm ~]# rm -f /opt/file{2..100}

[root@lvm ~]# ls /opt
file1

[root@lvm ~]# lsblk
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                        8:0    0   40G  0 disk
├─sda1                     8:1    0    1M  0 part
├─sda2                     8:2    0    1G  0 part /boot
└─sda3                     8:3    0   39G  0 part
  ├─VolGroup00-LogVol00  253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01  253:1    0  1.5G  0 lvm  [SWAP]
sdb                        8:16   0   10G  0 disk
└─vg_data-lv_data_corig  253:5    0   10G  0 lvm
  └─vg_data-lv_data-real 253:6    0   10G  0 lvm
    ├─vg_data-lv_data    253:2    0   10G  0 lvm
    └─vg_data-data_snap  253:8    0   10G  0 lvm  /opt
sdc                        8:32   0    2G  0 disk
└─vg_data-data_snap-cow  253:7    0    1G  0 lvm
  └─vg_data-data_snap    253:8    0   10G  0 lvm  /opt
sdd                        8:48   0    1G  0 disk
└─vg_data-cpool_cdata    253:3    0    2G  0 lvm
  └─vg_data-lv_data-real 253:6    0   10G  0 lvm
    ├─vg_data-lv_data    253:2    0   10G  0 lvm
    └─vg_data-data_snap  253:8    0   10G  0 lvm  /opt
sde                        8:64   0    1G  0 disk
├─vg_data-cpool_cdata    253:3    0    2G  0 lvm
│ └─vg_data-lv_data-real 253:6    0   10G  0 lvm
│   ├─vg_data-lv_data    253:2    0   10G  0 lvm
│   └─vg_data-data_snap  253:8    0   10G  0 lvm  /opt
└─vg_data-cpool_cmeta    253:4    0    8M  0 lvm
  └─vg_data-lv_data-real 253:6    0   10G  0 lvm
    ├─vg_data-lv_data    253:2    0   10G  0 lvm
    └─vg_data-data_snap  253:8    0   10G  0 lvm  /opt

[root@lvm ~]# mkdir /data_snap

[root@lvm ~]# mount /dev/vg_data/data_snap /data_snap/

[root@lvm ~]# ls /data_snap/
file1

[root@lvm ~]# umount /data_snap

[root@lvm ~]# umount /opt

[root@lvm ~]# lvconvert --merge /dev/vg_data/
data_snap  lv_data

[root@lvm ~]# lvconvert --merge /dev/vg_data/data_snap
  Merging of volume vg_data/data_snap started.
  vg_data/lv_data: Merged: 99.97%
  vg_data/lv_data: Merged: 100.00%

[root@lvm ~]# mount /dev/vg_data/lv_data /opt

[root@lvm ~]# ls /opt
file1    file13  file18  file22  file27  file31  file36  file40  file45  file5   file54  file59  file63  file68  file72  file77  file81  file86  file90  file95
file10   file14  file19  file23  file28  file32  file37  file41  file46  file50  file55  file6   file64  file69  file73  file78  file82  file87  file91  file96
file100  file15  file2   file24  file29  file33  file38  file42  file47  file51  file56  file60  file65  file7   file74  file79  file83  file88  file92  file97
file11   file16  file20  file25  file3   file34  file39  file43  file48  file52  file57  file61  file66  file70  file75  file8   file84  file89  file93  file98
file12   file17  file21  file26  file30  file35  file4   file44  file49  file53  file58  file62  file67  file71  file76  file80  file85  file9   file94  file99

[root@lvm ~]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk
├─sda1                    8:1    0    1M  0 part
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk
└─vg_data-lv_data_corig 253:5    0   10G  0 lvm
  └─vg_data-lv_data     253:2    0   10G  0 lvm  /opt
sdc                       8:32   0    2G  0 disk
sdd                       8:48   0    1G  0 disk
└─vg_data-cpool_cdata   253:3    0    2G  0 lvm
  └─vg_data-lv_data     253:2    0   10G  0 lvm  /opt
sde                       8:64   0    1G  0 disk
├─vg_data-cpool_cdata   253:3    0    2G  0 lvm
│ └─vg_data-lv_data     253:2    0   10G  0 lvm  /opt
└─vg_data-cpool_cmeta   253:4    0    8M  0 lvm
  └─vg_data-lv_data     253:2    0   10G  0 lvm  /opt
```
