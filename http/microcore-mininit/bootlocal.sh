#!/bin/sh
# put other system startup commands here

# configure eth0 with DHCP
/sbin/udhcpc -b -i eth0 -x hostname:$(/bin/hostname) -p /var/run/udhcpc.eth0.pid >/dev/null 2>&1 &

# alternatively configure static interface address and route
#ifconfig eth0 x.x.x.x netmask 255.255.255.0 up
#route add default gw y.y.y.y
#echo 'nameserver z.z.z.z' > /etc/resolv.conf
