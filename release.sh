#!/bin/sh

# Make a release of static-linux
# Runs as root from a debian wheezy host, other 
# linuxes are probably fine as well



# Aliases should be absolute paths names so as to prevent breakage.
DEVICMNT="$(pwd)/control"

BUILDDIR="$(pwd)/control" 

ARCHITEC=i386

BACKHOME=$(pwd) 

VERSNUMB=0.6.4 # version number for release 


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



