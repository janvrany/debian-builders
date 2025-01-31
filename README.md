# Debian Builders

An opinionated set of scripts to build Debian and Ubuntu images for
building and testing of software.

## How to build an image file

```
cd <image of choice>

truncate -s 5G root.img
guestfish -a root.img run : part-disk /dev/sda mbr : part-set-bootable /dev/sda 1 true : mkfs ext4 /dev/sda1 : list-filesystems

./build.sh root.img
./grub2.sh root.img

```

## How to install built image into libvirt instance

```
qemu-img convert -f raw -O qcow2 root.img root.qcow2
qemu-img resize -f qcow2 root.qcow2 50G
guestfish -a root.qcow2 -- run : part-resize /dev/sda 1 -1 : resize2fs /dev/sda1
guestfish -a root.qcow2 -- run : mount /dev/sda1 / : write /etc/hostname builder-deb12-x86-64-1 : umount-all
qemu-img snapshot -c "base" root.qcow2
qemu-img info root.qcow2
```

```
dd if=root.img bs=32M | pv -s 10G | ssh -oCompression=no host dd of=/dev/zvol/guests/root.qcow2 bs=32M
```

### Notes on QCOW2 performance

See [1], [2]. In my brief testing with `fio`, following combination gave me the best I/O performance on my system:

 * ZFS dataset with 4k record size

 * QCOW2 with `-o extended_l2=on,cluster_size=128k` (subcluster allocation, 128k cluster size)

 * Increase L2 cache size in libvirt [3] (search for `metadata_cache` in that document).
   This is important. You may use `script/compute_cache_size.py` to compute the value
   given size of virtual disk and size of QCOW2 cluster.

### TODO

  * integrate with Wayland

    https://michael.franzl.name/blog/posts/2023-12-02-run-graphical-wayland-applications-in-systemd-nspawn


[1]: https://blogs.igalia.com/berto/2015/12/17/improving-disk-io-performance-in-qemu-2-5-with-the-qcow2-l2-cache/
[2]: https://blogs.igalia.com/berto/2020/12/03/subcluster-allocation-for-qcow2-images/
[3]: https://libvirt.org/formatdomain.html#hard-drives-floppy-disks-cdroms
