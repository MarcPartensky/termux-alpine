#!/bin/sh

export MNT=`mktemp -d`
export DISK='/dev/vda'
export SWAPSIZE=8
export RESERVE=1

setup-interfaces -r
setup-ntp busybox
setup-apkrepos

apk update
apk upgrade
apk add eudev zfs parted e2fsprogs cryptsetup util-linux
setup-devd udev

modprobe zfs

partition_disk () {
 local disk="${1}"
 blkdiscard -f "${disk}" || true

 parted --script --align=optimal  "${disk}" -- \
 mklabel gpt \
 mkpart EFI 1MiB 4GiB \
 mkpart rpool 4GiB -$((SWAPSIZE + RESERVE))GiB \
 mkpart swap  -$((SWAPSIZE + RESERVE))GiB -"${RESERVE}"GiB \
 set 1 esp on \

 partprobe "${disk}"
}

for i in ${DISK}; do
   partition_disk "${i}"
done

for i in ${DISK}; do
   cryptsetup open --type plain --key-file /dev/random "${i}"3 "${i##*/}"3
   mkswap /dev/mapper/"${i##*/}"3
   swapon /dev/mapper/"${i##*/}"3
done


# shellcheck disable=SC2046
zpool create \
    -o ashift=12 \
    -o autotrim=on \
    -R "${MNT}" \
    -O acltype=posixacl \
    -O canmount=off \
    -O dnodesize=auto \
    -O normalization=formD \
    -O relatime=on \
    -O xattr=sa \
    -O mountpoint=none \
    rpool \
   $(for i in ${DISK}; do
      printf '%s ' "${i}2";
     done)

zfs create -o canmount=noauto -o mountpoint=legacy rpool/root

zfs create -o mountpoint=legacy rpool/home
mount -o X-mount.mkdir -t zfs rpool/root "${MNT}"
mount -o X-mount.mkdir -t zfs rpool/home "${MNT}"/home

for i in ${DISK}; do
 mkfs.vfat -n EFI "${i}"1
done

for i in ${DISK}; do
 mount -t vfat -o fmask=0077,dmask=0077,iocharset=iso8859-1,X-mount.mkdir "${i}"1 "${MNT}"/boot
 break
done

BOOTLOADER=none setup-disk -k lts -v "${MNT}"

# from http://www.rodsbooks.com/refind/getting.html
# use Binary Zip File option
apk add curl
curl -L http://sourceforge.net/projects/refind/files/0.14.0.2/refind-bin-0.14.0.2.zip/download \
    --output refind.zip
unzip refind

mkdir -p "${MNT}"/boot/EFI/BOOT
find ./refind-bin-0.14.0.2/ -name 'refind_x64.efi' -print0 \
| xargs -0I{} mv {} "${MNT}"/boot/EFI/BOOT/BOOTX64.EFI
rm -rf refind.zip refind-bin-0.14.0.2

tee -a "${MNT}"/boot/refind-linux.conf <<EOF
"Alpine Linux" "root=ZFS=rpool/root"
EOF


umount -Rl "${MNT}"
zfs snapshot -r rpool@initial-installation
zpool export -a
