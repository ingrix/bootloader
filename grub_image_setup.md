## Initialize the disk image

Partition the disk image using e.g. fdisk
```
# truncate -s 128M hdd.img
# fdisk hdd.img
# fdisk -l hdd.img 
Disk hdd.img: 128 MiB, 134217728 bytes, 262144 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x00000000

Device     Boot Start    End Sectors  Size Id Type
hdd.img1         2048 262143  260096  127M 83 Linux
```

## Get GRUB installed on a virtual disk image:

### Setup loopback devices
```
# losetup -fP hdd.img 
# losetup -l  
NAME       SIZELIMIT OFFSET AUTOCLEAR RO BACK-FILE                                        DIO
/dev/loop0         0      0         0  0 /home/ingrix/Git/bigbluewhale/bootloader/hdd.img   0
# ls /dev/loop0*
/dev/loop0  /dev/loop0p1
# mount /dev/loop0p1 /mnt/loop0p1/
```

### Set up the partition map
```
# mkdir -p /mnt/loop0p1/
# echo -e '(hd0) /dev/loop0\n(hd0,1) /dev/loop0p1' > /mnt/loop0p1/boot/grub/device.map
```

### Install GRUB

```
# grub-install --modules part_msdos --boot-directory=/mnt/loop0p1 --grub-mkdevicemap=/mnt/loop0p1/boot/grub/device.map /dev/loop0
```

The `--modules part_msdos` part is very important, otherwise GRUB won't know
what kind of partition type to use

### Edit the grub.cfg file
```
# grub.cfg for a TinyCore image
menuentry "linux" {
  linux /boot/vmlinuz
  initrd /boot/core.gz
}
```
