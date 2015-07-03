#!/bin/sh

# Static-linux
# (C) 2013-2014, 2015  cgraf GPL license
# This script organizes and automates all other aspects of the
# build process by sourcing various function libraries from
# "lib/*tmplts/????-*".
								

. lib/initialize
initialize

# log
# exec 1> log.txt




dog()
{ 
	while read -r i
	do 	printf '%s\n' "$i"
	done 
}


for i in `dog <<EOF
#set_buildroot_env 
#set_buildroot_altenv
#set_crosstool_env
EOF`
do case $i in
    \#*) ;;
      *) "${i}" ;;
   esac
done



# Get package source code from the address_book.

for i in `dog <<EOF
#get_linux
#get_bash
#get_busybox
#get_syslinux
#get_coreutils
#get_squashfs
get_buildroot
#get_htop
#get_nmap
#get_crosstool_ng
#get_example
#get_rsync
#get_nano
EOF`
do case $i in
   \#*) ;;
     *) j="${src}/$(echo $i|sed "s|get_||g")"
        echo "${i}" "${j}"
	[ -e "${j}" ] || "${i}" "${j}"
	;;
   esac
done




# Main body of the build process (configure and make).

for i in `dog <<EOF
	

#configure_linux
#configure_crosstool_ng 

#make_crosstool_ng 

#make_x86_64_statics_min
#make_buildroot_raspi
#make_x86_static_min
#experimental_bld
make_buildroot_expero 
#make_buildroot_x86_64_busybox

#make_x86_64_xorg


#make_syslinux
#make_busybox
#make_bash
#make_linux
#make_coreutils
#make_squashfs
#make_htop
#make_dash
#make_nmap
#make_mc
#make_rsync
#make_syslinux
#make_nano
	

#install_busybox
#install_bash
#install_linux
#install_coreutils
#install_squashfs
#install_htop
#install_crosstool-ng
	

#configure_linux
#make_linux
	
EOF`
        
do case $i in
   \#*) ;;
     *) "${i}"
	;;
   esac
done


