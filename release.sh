#!/bin/sh

# Make a release of static-linux
# Runs as root from a debian wheezy host, other 
# linuxes are probably fine as well



# Aliases should be absolute paths names so as to prevent breakage.
DEVICMNT="$(pwd)/control" 

VERSNUMB=0.6.4 # version number for release 


# clean up the build directory.
rm -rf "${DEVICMNT}"

# update the package manager
if [ -f tools/pkg_stx ]
then 	echo "tools/pkg_stx ok"
	./tools/pkg_stx update
else 	echo "tools/pkg_stx not found"
	exit 
fi 


install_base()
{
	mkdir -p "${DEVICMNT}" 
	#cp -r skeleton-0.0.0/skeleton/* "${DEVICMNT}" 
	echo "DESTDIR=${DEVICMNT}/" >> config
	./tools/pkg_stx install skeleton
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
	#echo "DESTDIR=${DEVICMNT}/sbin/" >> config
	echo "DESTDIR=${DEVICMNT}/" >> config
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

install_file()
{
	echo "DESTDIR=${DEVICMNT}/" >> config
        ./tools/pkg_stx install file
}

install_alsa()
{
        echo "DESTDIR=${DEVICMNT}/bin/" >> config
        ./tools/pkg_stx install alsa-utils
}



install_base
install_terminfo 
install_kernel
install_busybox
install_ssh 
install_htop
install_file
install_alsa


# This remastery tool can be obtained from
# https://github.com/cmgraff/backup however 
# for now static-linux uses a slightly modified version


./backup.sh \
--root=control/ \
--backup \
--remaster \
--size=2 \
--image="static-linux-${VERSNUMB}.img" \
--title=static-linux-${VERSNUMB} \
--bootld=grub





