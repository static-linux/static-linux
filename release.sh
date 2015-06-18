#!/bin/sh

# Main wrapper script for the statix rewrite.
# Runs as root from a debian wheezy host.



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
	cp -r skeleton/* "${BUILDDIR}" 
	
}


install_terminfo()
{
	echo "DESTDIR=${DEVICMNT}/usr/share/" >> config
        ./tools/pkg_stx install terminfo
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

	#cd "${BUILDDIR}"/sbin
	#./busybox --install .
	#./busybox --install ../bin 
	#ln busybox init   2>/dev/null
	#ln busybox getty  2>/dev/null
	#ln busybox mount  2>/dev/null
	#cd "${BACKHOME}" 
}
install_htop()
{
	echo "DESTDIR=${DEVICMNT}/bin/" >> config
        ./tools/pkg_stx install htop

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


closedisk()
{
	umount "${DEVICMNT}"
}



# build
opendisk
makebase
install_terminfo 
install_kernel
install_busybox
install_ssh 
install_htop
closedisk



