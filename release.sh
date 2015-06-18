#!/bin/sh

# Main wrapper script for the statix rewrite.
# Runs as root from a debian wheezy host.


# liveuser "live"
# root "liveroot"




# Aliases should be absolute paths names so as to prevent breakage.
DEVICMNT="$(pwd)/control"

BUILDDIR="$(pwd)/control" 

ARCHITEC=i386

BACKHOME=$(pwd) 

VERSNUMB=0.6.4 # version number for release 

# chmod various files to harden security.
HARDEN=YES 


# clean up the build directory.
rm -rf "${BUILDDIR}"

# update the package manager
if [ -f tools/pkg_stx ]
then 	echo "tools/pkg_stx ok"
	./tools/pkg_stx update
else 	echo "tools/pkg_stx not found"
	exit 
fi

install_configuration()
{
mkdir -p "${BUILDDIR}"/etc/rc.d
cat >> "${BUILDDIR}"/etc/inittab << EOF
null::sysinit:/bin/mount -t proc proc /proc
null::sysinit:/bin/mount -o remount,rw /
null::sysinit:/sbin/busybox --install /sbin
null::sysinit:/sbin/busybox --install /bin
null::sysinit:/bin/mkdir -p /dev/pts
null::sysinit:/bin/mkdir -p /dev/shm
null::sysinit:/bin/mount -a
null::sysinit:/bin/mount -t devpts devpts /dev/pts
null::sysinit:/bin/hostname -F /etc/hostname
tty1::respawn:/sbin/getty -L tty1 115200 vt100
null::shutdown:/bin/umount -a -r
null::shutdown:/bin/swapoff -a
EOF

cat >> "${BUILDDIR}"/etc/inittab << EOF
null::sysinit:/sbin/chmod 4755 /sbin/busybox
null::sysinit:/etc/rc.d/udhcpc start
null::sysinit:/etc/rc.d/dropbear start
null::sysinit:/etc/rc.d/syslogd start
null::sysinit:/etc/rc.d/klogd start
EOF

[ "$HARDEN" = "YES" ] && chmod 400 "${BUILDDIR}"/etc/inittab

cat >> "${BUILDDIR}"/etc/rc.d/klogd << EOF
#!/bin/sh
case \$1 in
 start) /sbin/klogd
        ;;
  stop) /sbin/killall klogd
        ;;
     *) echo "klogd [start|stop]"
        ;;
esac
EOF

cat >> "${BUILDDIR}"/etc/rc.d/syslogd << EOF
#!/bin/sh
case \$1 in
 start) /sbin/syslogd
        ;;
  stop) /sbin/killall syslogd
        ;;
     *) echo "syslogd [start|stop]"
        ;;
esac
EOF


cat >> "${BUILDDIR}"/etc/rc.d/udhcpc << EOF
#!/bin/sh
case \$1 in
 start) /sbin/udhcpc
        ;;
  stop) /sbin/killall udhcpc
        ;;
     *) echo "udhcpc [start|stop]"
        ;;
esac
EOF

cat >> "${BUILDDIR}"/etc/rc.d/dropbear << EOF
#!/bin/sh
case \$1 in
 restart) /sbin/kill "\$(cat /var/run/dropbear.pid)"
          sleep 1 ; dropbear -g -w -R -P
          ;;
  status) cat /var/run/dropbear.pid && echo dropbear running
          ;;
   start) dropbear -g -w -R -P
          ;;
    stop) /sbin/kill "\$(cat /var/run/dropbear.pid)"
          ;;
       *) echo "dropbear [start|stop|status|restart]"
          ;;
esac
EOF



cat >> "${BUILDDIR}"/etc/rc.d/httpd << EOF
#!/bin/sh
case \$1 in
 restart) /sbin/kill "\$(( \$(cat /var/run/httpd.pid) + 1 ))"
          /sbin/httpd -h /www & echo "\$!">/var/run/httpd.pid
          ;;
  status) cat /var/run/httpd.pid && echo httpd running
          ;;
   start) [ -d /www ] || (mkdir -p /www ; echo "It works">/www/index.html)
          httpd -h /www & echo "\$!" >/var/run/httpd.pid
          ;;
    stop) /sbin/kill "\$(( \$(cat /var/run/httpd.pid) + 1 ))"
          ;;
       *) echo "httpd [start|stop|status|restart]"
          ;;
esac
EOF


cat >> "${BUILDDIR}"/etc/rc.d/crond <<EOF
#!/bin/sh
# (C) 2014, "/etc/rc.d/crond", cgraf, GPL 
case \$1 in
 restart) kill "\$(( \$(cat /var/run/crond.pid) + 1 ))"
          crond -c /cron & echo "\$!">/var/run/crond.pid
          ;;
  status) cat /var/run/crond.pid && echo crond running
          ;;
   start) if [ -e /cron ] 
          then echo ok
          else mkdir -p /cron/cron.hourly /cron/cron.weekly /cron/cron.minutely
               mkdir -p /cron/cron.daily /cron/cron.monthly
               echo "PATH=/sbin">>/cron/root
               echo "*  * *  * * /sbin/run-parts /cron/cron.minutely">>/cron/root
               echo "1  * *  * * /sbin/run-parts /cron/cron.hourly">>/cron/root
               echo "6  3 *  * * /sbin/run-parts /cron/cron.daily">>/cron/root
               echo "10 4 *  * 2 /sbin/run-parts /cron/cron.weekly">>/cron/root
               echo "12 3 20 * * /sbin/run-parts /cron/cron.monthly">>/cron/root
          fi
          crond -c /cron & echo "\$!" > /var/run/crond.pid
          ;;
    stop) kill "\$(( \$(cat /var/run/crond.pid) + 1 ))"
          echo >/var/run/crond.pid
          ;; 
       *) echo "/etc/rc.d/crond [start|stop|status|restart]" 
          ;;
esac
EOF

chmod +x "${BUILDDIR}"/etc/rc.d/* 


cat > "${BUILDDIR}"/etc/fstab << EOF
proc /proc proc defaults 0 0
tmpfs /tmp tmpfs rw 0 0
EOF

cat > "${BUILDDIR}"/etc/hostname << EOF
statix-${ARCHITEC}
EOF


cat > "${BUILDDIR}"/etc/passwd << EOF
root:x:0:0:root:/root:/bin/sh
liveuser:x:1000:1000:Linux User,,,:/home/liveuser:/bin/sh
EOF

cat > "${BUILDDIR}"/etc/shadow << EOF
root:0hmaax32bUgu6:16218:0:99999:7:::
liveuser:TF6ftmedd9S5w:16218:0:99999:7:::
EOF
chmod 540 "${BUILDDIR}"/etc/shadow

cat > "${BUILDDIR}"/root/.bashrc << EOF
PS1="\[\033[35m\]\[\033[m\]\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[66;1m\]\w\[\033[m\]# "
EOF

cat > "${BUILDDIR}"/home/liveuser/.bashrc << EOF
PS1="\[\033[35m\]\[\033[m\]\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\] "
EOF


cat > "${BUILDDIR}"/etc/profile << EOF

[ -e ~/.bashrc ] && . ~/.bashrc

# Define print colors
SYSRED="\033[31m"
SYSGRE="\033[32m"
SYSGOL="\033[33m"
SYSBLU="\033[34m"
SYSPUR="\033[35m"
SYSTEA="\033[36m"
SYSNOR="\033[39m"


if [ ! -e /etc/firstrun.stamp ] 
then echo -e "\${SYSGRE}Change the passwords for root and liveuser"
     echo -e "\${SYSGRE}Restart the dropbear ssh server. '/etc/rc.d/dropbear restart' " 
     echo -e "\${SYSGRE}For more information see '/usr/share/Getting_started.txt'\${SYSNOR}"
     echo
     touch /etc/firstrun.stamp
fi


EOF

cat > "${BUILDDIR}"/init << EOF
#!/bin/sh 
/bin/mount -t devtmpfs devtmpfs /dev 
exec 0</dev/console
exec 1>/dev/console
exec 2>/dev/console
exec /sbin/init \$*
EOF



chmod 700 "${BUILDDIR}"/init



# Set some defaults for the bootloader.
cat > "${DEVICMNT}"/boot/syslinux/extlinux.conf <<EOF
MENU COLOR screen	30;40        #40000000 #00000000 std
MENU COLOR title        37;40        #40000000 #00000000 std
MENU COLOR border       30;40        #40000000 #00000000 std
MENU COLOR unsel        37;40        #40000000 #00000000 std
MENU COLOR sel		7;37;40      #e0000000 #20ff8000 all
UI menu.c32
TIMEOUT 20 
EOF



cat >> "${DEVICMNT}"/boot/syslinux/extlinux.conf <<EOF
LABEL Statix Linux ${ARCHITEC} "/dev/sda"
KERNEL /boot/bzImage
APPEND root=/dev/sda init=/sbin/init 
EOF


cat > "${BUILDDIR}"/etc/motd <<EOF 

Welcome to Statix Linux ${ARCHITEC} !! 

EOF
cp -r docs/* "${BUILDDIR}"/usr/share/

cat >> "${BUILDDIR}/etc/tools/pkg_stx_stx/config" <<EOF
# This is a blank configuration file for tools/pkg_stx_stx
# See /usr/share/tools/pkg_stx_stx.txt for information 
EOF

}


opendisk()
{
	mkdir -p "${BUILDDIR}" "${DEVICMNT}" 2>/dev/null 
	APROXSIZ="10"
	dd if=/dev/zero of="statix-${ARCHITEC}-${VERSNUMB}.img" bs=2M count="${APROXSIZ}" 
	mkfs.ext4 -F "statix-${ARCHITEC}-${VERSNUMB}.img"
	mount "statix-${ARCHITEC}-${VERSNUMB}.img" "${DEVICMNT}" 
	mkdir -p "${DEVICMNT}"/boot/syslinux
	cp /usr/lib/syslinux/menu.c32 "${DEVICMNT}"/boot/syslinux/
	extlinux --install "${DEVICMNT}"/boot/syslinux/ 
}


makebase()
{
	mkdir -p "${BUILDDIR}" 2>/dev/null
	cd "${BUILDDIR}" 

	mkdir -p etc/tools/pkg_stx_stx
	mkdir -p var/tools/pkg_stx_stx


	mkdir -p usr/share/udhcpc etc/dropbear etc/rc.d/ mnt media
	mkdir -p root dev bin proc var/run var/log opt sys
	mkdir -p tmp home/liveuser sbin boot/syslinux
	cd "${BACKHOME}"


	cp -r lib/terminal/terminfo "${BUILDDIR}"/usr/share/ 
	cp tools/* "${BUILDDIR}"/sbin
	cp -r lib/system-skeleton/etc/udhcpc/default.script "${BUILDDIR}"/usr/share/udhcpc 
	cp ngircd.conf "${BUILDDIR}"/etc/
}


install_kernel()
{ 
	echo "DESTDIR=${DEVICMNT}/boot/" >> config
	./tools/pkg_stx install linux 
}


install_busybox()
{ 
	echo "DESTDIR=${DEVICMNT}/sbin/" >> config
	./tools/pkg_stx install busybox

	cd "${BUILDDIR}"/sbin
	./busybox --install .
	./busybox --install ../bin 
	ln busybox init   2>/dev/null
	ln busybox getty  2>/dev/null
	ln busybox mount  2>/dev/null
	cd "${BACKHOME}" 
}


install_ssh()
{ 
	echo "DESTDIR=${DEVICMNT}/bin/" >> config
	./tools/pkg_stx install dropbear
	

	cd "${BUILDDIR}"/bin
	strip dropbearmulti
	ln dropbearmulti dropbear
	ln dropbearmulti dropbearkey
	ln dropbearmulti dropbearconvert
	ln dropbearmulti ssh
	ln dropbearmulti dbclient
	ln dropbearmulti scp
	cd "${BACKHOME}"

}


closdisk()
{
	umount "${DEVICMNT}"
}



# build
opendisk
makebase
install_configuration
install_kernel
install_busybox
install_ssh 
closdisk



