# Debian Builders

An opinionated set of scripts to build Debian and Ubuntu images for
building and testing of software.

## How to build an image file

```
cd <image of choice>

truncate -s 10G root.img
guestfish -a root.img run : part-disk /dev/sda mbr : part-set-bootable /dev/sda 1 true : mkfs ext4 /dev/sda1 : list-filesystems

./build.sh root.img
./grub2.sh root.img

qemu-img convert -f raw -O qcow2 root.img root.qcow2
```

## How to install built image into libvirt instance

```
dd if=root.img bs=32M | pv -s 10G | ssh -oCompression=no host dd of=/dev/zvol/guests/root.qcow2 bs=32M
```