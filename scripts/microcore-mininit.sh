# Install tinycore on harddisk
set -e -x

. /etc/init.d/tc-functions
FILE_URL=http://`getbootparam http`
KERNEL_RELEASE=`uname -r`

# format harddisk
echo -e 'n\np\n1\n\n\na\n1\nw' | sudo fdisk -H16 -S32 /dev/sda
sudo mkfs.ext2 /dev/sda1

# copy system to harddisk
sudo mkdir /mnt/sda1
sudo mount /dev/sda1 /mnt/sda1
sudo mount /mnt/sr0
sudo cp -a /mnt/sr0/boot /mnt/sda1/
sudo umount /mnt/sr0

# modify bootloader config
sudo mv /mnt/sda1/boot/isolinux /mnt/sda1/boot/extlinux
cd /mnt/sda1/boot/extlinux
sudo rm boot.cat isolinux.bin f?
sudo mv isolinux.cfg extlinux.conf
sudo sed -i -e '$ d' boot.msg
sudo sed -i -e '/^label mc/,$ d' -e '/^ *$/ d' -e '1 i serial 0 38400' -e 's/\(append .*\)/\1 console=ttyS0,38400 console=tty0/' -e 's/\(initrd .*\)/\1,\/boot\/microcore-mininit.gz/' extlinux.conf
cd

# make disk bootable
tce-load -wi syslinux
sudo sh -c 'cat /usr/local/share/syslinux/mbr.bin > /dev/sda'
sudo /usr/local/sbin/extlinux --install /mnt/sda1/boot/extlinux

# make microcore-mininit base directory
sudo mkdir microcore-mininit
sudo chmod 755 microcore-mininit
sudo sh -c 'echo -e "/etc\n/etc/init.d\n/opt\n/root\n/sbin" | cpio -p microcore-mininit'
cd microcore-mininit

# new boot script
sudo cp -p /etc/init.d/rcS etc/init.d/
sudo sed -i -e 's/^\(.*tc-config.*\)/#\1/' -e '/tc-config/ a /etc/init.d/microcore_mininit-config' etc/init.d/rcS
sudo wget -O etc/init.d/microcore_mininit-config $FILE_URL/microcore-mininit/microcore_mininit-config
sudo chmod 755 etc/init.d/microcore_mininit-config

# new user initialization script
sudo wget -O opt/bootlocal.sh $FILE_URL/microcore-mininit/bootlocal.sh
sudo chown root:staff opt/bootlocal.sh
sudo chmod 775 opt/bootlocal.sh

# inittab
sudo cp -p /etc/inittab etc/
sudo sed -i -e 's/^\(tty1:[^:]*\):respawn/\1:askfirst/' -e '/tty6/ a ttyS0::askfirst:/sbin/getty -nl /sbin/autologin 38400 ttyS0 xterm' etc/inittab
sudo cp -p /etc/securetty etc/
sudo sed -i -e 's/^# *ttyS0/ttyS0/' etc/securetty
sudo sh -c 'echo -e "#!/bin/busybox ash\nexec login -f root" > sbin/autologin'
sudo chown root:staff sbin/autologin
sudo chmod 775 sbin/autologin
sudo sh -c 'echo -e "#!/bin/sh\nTCUSER=\"\$(cat /etc/sysconfig/tcuser)\"\nexec /bin/su - \"\$TCUSER\"" > root/.profile'
sudo chown root:staff root/.profile
sudo chmod 664 root/.profile

# install ipv6 kernel module
mkdir /tmp/loop
tce-load -w ipv6-${KERNEL_RELEASE}
sudo mount -o loop /tmp/tce/optional/ipv6-${KERNEL_RELEASE}.tcz /tmp/loop
sudo cp -a /tmp/loop/usr/local/lib .
sudo umount /tmp/loop

# install iproute2 and nano
rm /tmp/tce/optional/*
tce-load -w iproute2 nano
rm -f /tmp/tce/optional/db.tcz*
find /tmp/tce/optional -name "*.tcz" | while read tce; do
	sudo mount -o loop "$tce" /tmp/loop
	sudo cp -a /tmp/loop/usr .
	sudo umount /tmp/loop
done
sudo rm usr/local/sbin/arpd
sudo rmdir usr/local/var/lib/arpd
sudo rmdir --ignore-fail-on-non-empty usr/local/var/lib usr/local/var

# create kernel module dependencies and library cache
sudo mkdir -p /tmp/chroot
sudo sh -c "cd /tmp/chroot; zcat /mnt/sda1/boot/core.gz | cpio -idmu"
sudo cp -a * /tmp/chroot/
sudo chroot /tmp/chroot depmod -a
sudo cp -p /tmp/chroot/lib/modules/${KERNEL_RELEASE}/modules.* lib/modules/${KERNEL_RELEASE}/
sudo chroot /tmp/chroot /sbin/ldconfig
sudo cp -p /tmp/chroot/etc/ld.so.cache etc/

# create microcore-mininit initrd
sudo sh -c 'find * | sort | cpio -o -H newc | gzip -9 > /mnt/sda1/boot/microcore-mininit.gz'

sudo umount /mnt/sda1
exit 0
