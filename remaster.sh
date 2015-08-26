#!/bin/sh 

# Defaults
START="$(pwd)"
BACKUP="0"
CLEAN="0"
RESTORE="0"
REMASTER="0"
TEST="0"
FS="ext4"
IMAGE="binary.img"
SIZE=""
COMPRESSION="gzip" 
UNARCHIVE="tar -x" 
RPATH="."
HOMEDIR="home" 
NAME="backup"
ARCV="tar"
SUFX="gz" 
ARROOT="/"
FILESYS="mkfs.ext4" 
ARCVTOOL="tar"
SYSLINUX="0" 
TARBALL="${NAME}.${ARCV}.${SUFX}" 
BOOTLOADER="syslinux" 
QUICKTEST="0"
TOOLS="du dd parted losetup "
TITLE="Remastered backup"

# functions
unmount()
{
	umount "$RPATH"
        losetup -d "${LOOP1}"
        losetup -d "${LOOP2}"
}

error()
{
	unmount 
        printf "a failure occured. exiting ...\n"
        exit 1

}

duwrap()
{ 
        for i in $(du -cs $@ 2>/dev/null)
        do      eval ARRAY_"$C"="$i"
                C=$(( $C + 1 ))
        done

        C=$(( $C - 2 ))

        printf "%s" "$(eval printf '$'ARRAY_$C )"
} 

cdwrap()
{
	if ! cd "$1"
        then    printf "Unable to cd to %s. exiting..\n" "$1"
                error
        fi
}

checkconfig()
{ 
	# Set the naming convention and utilities
	# for the archive type
        case "${ARCV}" in
                iso) 
			ARCVTOOL="xorriso"
                	;;
                cpio) 
                	UNARCHIVE="cpio -i --no-absolute-filenames"
			ARCVTOOL="cpio find"
                	;;
                tar) 
			UNARCHIVE="tar -x" 
			ARCVTOOL="tar"
                	;;
                *)
                	printf "%s archive type not recognized\n" "$ARCV"
                	exit 1
                	;;
        esac 

	case "$COMPRESSION" in
		gzip)
			SUFX="gz"
			;;
		xz)
			SUFX="xz"
			;;
		bzip2)
			SUFX="bz2"
			;;
		lzma)
                	SUFX="lzma"
                	;;
		lzip)
                	SUFX="lz"
                	;;
                lzop)
                	SUFX="lzo"
                	;;
		*)
			printf "%s compression type not recognized\n" "$COMPRESSION" 
                	exit 1
                ;; 
	esac
	# identify the user's filesystem decision 
        case "$FS" in
                ext2)
                	FILESYS="mkfs.ext2"
                	;;
                ext3)
                	FILESYS="mkfs.ext3"
                	;;
                ext4)
                	FILESYS="mkfs.ext4"
                	;;
                btrfs)
                	FILESYS="mkfs.btrfs"
                	;;
                vfat)
               	 	FILESYS="mkfs.vfat"
                	SYSLINUX="1"
                	;;
                *)
                	printf "%s filesystem type not supported\n" "$FS"
                	exit 1
                	;;
        esac 
	# Set the compression and archiving tools
	# according to the backup file's triplet
	case "$SUFX" in
		gz)
			COMPRESSION="gzip" 
			;;
		xz)
			COMPRESSION="xz" 
			;;
		bz2)
			COMPRESSION="bzip2"
			;;
		lzma)
                	COMPRESSION="lzma"
                	;;
                lz)
                	COMPRESSION="lzip"
                	;;
                lzop)
                	COMPRESSION="lzo"
                	;;
		*)
			printf "%s compression type not recognized\n" "$SUFX" 
			exit
			;;
	esac 
	
	# Identify the tool needed for the bootloader selection
	case "$BOOTLOADER" in
		grub) 
			BOOTTOOL="grub-install" 
			;;
		syslinux)   
                        BOOTTOOL="syslinux"
                        ;;
		extlinux)
			BOOTTOOL="extlinux"
                        ;;

	esac 

	TARBALL="${NAME}.${ARCV}.${SUFX}" 
}

help()
{ 
	printf "\`backup': Backup and/or remaster a linux OS\n"
	printf "(C) Copyright 2015 \`backup' CM Graff, GPLv2\n\n"
	printf "Options:\n" 
	printf "        --archive=      iso|tar|cpio          '%s'\n" "${ARCV}" 
	printf "        --backup        Perform a system backup and save\n"
	printf "                           as '%s'.\n" "${TARBALL}"
       	printf "        --remaster      Remaster '%s'\n" "${TARBALL}"
	printf "                           onto a bootable disk image\n"
       	printf "                           named '%s'.\n" "${IMAGE}" 
	printf "        --file=         Create or restore from FILE\n" 
	printf "        --compression=  gzip|bzip2|xz\n"
	printf "                        lzip|lzop|lzma        '%s'\n" "${COMPRESSION}" 
	printf "        --rpath=        Restore path          '%s'\n" "${RPATH}"
       	printf "        --fs=           ext2|ext3|ext4|btrfs  '%s'\n" "${FS}"
	printf "        --size=         Image size in 100M blocks\n" 
	printf "        --root=         source dir            '%s'\n" "${ARROOT}"
	printf "        --bootld=       grub|syslinux         '%s'\n" "${BOOTLOADER}" 
	printf "        --whome         Include /home\n"
	printf "        --help          Display this menu\n"
	echo "        --title=        Title of remastered image"
	echo
	printf "Perform a system backup of \"/\":\n"
	printf "  backup --backup\n\n"
        printf "Restore from an existing backup:\n"
        printf "  backup --file=FILE --rpath=/path\n\n"
        printf "Remaster \"/\" onto a bootable disk image\n"
        printf "  backup --backup --remaster\n\n"
	exit 0
} 

# parse options
if [ -z "$1" ]
then 	help 
fi



for i in "$@"
do
	case "$i" in 
	-h|--help)
		help
		;;
	--backup) 
		BACKUP="1"
		;;
	--clean) 
		CLEAN="1"
		;; 
	--remaster) 
		BOOTTOOL="$BOOTLOADER"
       	        REMASTER="1"
		RPATH="${START}/mnt"
		checkconfig
               	;;	 
	--test)
                TEST="1" 
                ;; 
	--whome) 
		HOMEDIR="override" 
                ;;
	--quick)
                QUICKTEST="1"
                ;;
	--file=*)
		#RESTORE="1"
		# extract the components of the backup file's name 
		STORE="${1#*=}"
		HOLD="${STORE%.*}"
		SUFX="${1##*.}"
		ARCV="${HOLD##*.}"
		NAME="${HOLD%.*}" 
		checkconfig
		# Check if the restore source exists
		if ! [ -e "$TARBALL" ]
		then 	printf "'%s' not found!\n" "${TARBALL}" 
			printf "switching to creation mode\n"
			BACKUP="1"
		fi 
		
                ;; 
	--fs=*)
		FS="${1#*=}" 
		checkconfig 
		;; 
	--compression=*) 
                COMPRESSION="${1#*=}" 
		checkconfig 
                ;;
	--archive=*) 
		ARCV="${1#*=}"
		checkconfig 
                ;;
	--image=*)
                IMAGE="${1#*=}"
                ;; 
	--rpath=*) 
		RPATH="${1#*=}"
                ;;
	--size=*)
                SIZE="${1#*=}"
                ;;
	--root=*)
                ARROOT="${1#*=}"
                ;;
	--bootld=*) 
		BOOTLOADER="${1#*=}"
		checkconfig
                ;;
	--title=*)
		TITLE="${1#*=}"
		;;
		*)
		printf "%s not found!\n" "$1" 
		printf "Try \`backup --help' for more information.\n" 
		exit 1
		;;
	
	esac 
	shift
done 

# Clean everything and prepare for a new build
if [ $CLEAN = "1" ]
then 	rm -rf "${IMAGE}" binary.img
	rm -rf "${TARBALL}" backup.tar
	umount mnt
	rm -rf mnt 
	printf "done.\n"
	exit 0
fi


# Check for dependencies
TOOLS="${TOOLS} ${ARCVTOOL} ${COMPRESSION} ${FILESYS}" 
for CMD in $TOOLS 
do 	printf "Checking dependency..\n"
	if command -v "$CMD"
        then   	printf "\`%s' ok\n" "${CMD}"
        else   	printf "\`%s' not found!!\n" "${CMD}"
                exit 1
        fi
done 


# Create a system backup stage 1
if [ $BACKUP = "1" ]
then 	# Get a list of useable directories 

	cdwrap "${ARROOT}" 

	DIRLIST=""

	for DIR in *
	do 	case "$DIR" in 
		*${HOMEDIR}*) 
			;; 
		*proc*)
			;;
		*sys*)
			;;
		*tmp*)
			;; 
		*)	printf "selecting /%s\n" "$DIR"
			DIRLIST="${DIRLIST} ${DIR} "
			# this is for iso9660 only
		        if [ -d "${DIR}" ]
                        then 	GRAFTDIR="${GRAFTDIR} ${DIR}=${DIR} "
                        else 	GRAFTFILE="${GRAFTFILE} ${DIR} "
                        fi
			;;
		esac
	done

	
	# Aproximate size for remastered image 
	#SIZE=$(duwrap ${DIRLIST} )
	#SIZE=$(( $SIZE + ( $SIZE / 4 ) ))
	#SIZE=$(( $SIZE / 100000 ))
	printf "size was %s\n" "$SIZE" 
	
	
	# Determine archive type 
	ARCHIVE="tar -c $DIRLIST" 
	if [ "$ARCV" = "iso" ]
	then 	ARCHIVE="xorriso -as mkisofs -R -graft-points $GRAFTDIR $GRAFTFILE" 
		#ARCHIVE="genisoimage -R -graft-points $GRAFTDIR $GRAFTFILE"
	fi 

	if [ "$ARCV" = "cpio" ]
        then 	FIND="find ${DIRLIST}"
		ARCHIVE="cpio -o -H newc "
	fi 

	# Create and compress the archive
	printf "Archiving and compressing into %s/%s\n" "${START}" "${TARBALL}"
	$FIND | $ARCHIVE | "$COMPRESSION" > "${START}/${TARBALL}"
	cdwrap "$START"

fi 
        

# Remastery stage 1 ( create and mount bootable media )
if [ $REMASTER = "1" ]
then 	cdwrap "$START"
	# Create a disk image 
	
	SIZE=${SIZE:="50"} 
	mkdir -p "$RPATH" 
	dd if=/dev/zero of="${IMAGE}" bs=10M count="${SIZE}"
	[ "$?" != "0" ] && error

	# partition 
	LOOP1="$(losetup -f --show ${IMAGE} )" 
	[ "$?" != "0" ] && error
	
	parted "${LOOP1}" mklabel msdos -s -m 
	[ "$?" != "0" ] && error 
	
	parted "${LOOP1}" mkpart primary -s -m 9999872b 100%
	[ "$?" != "0" ] && error
	
	parted "${LOOP1}" set 1 boot on 
	[ "$?" != "0" ] && error 
	
	LOOP2="$(losetup -f --show -o 9999872 ${IMAGE} )"
	[ "$?" != "0" ] && error
	
	# format
	mkfs.$FS "${LOOP2}" 
	[ "$?" != "0" ] && error
	
	mount "${LOOP2}" "${RPATH}"
	[ "$?" != "0" ] && error 

	# Bootloader
	
	if [ "$BOOTLOADER" = "syslinux" ]
        then 	dd conv=notrunc \
                bs=440 count=1 \
                if=/usr/lib/syslinux/mbr.bin of="${LOOP1}"
		[ "$?" != "0" ] && error
		#gptmbr.bin 

		if [ "$SYSLINUX" = "0" ]
        	then 	extlinux --install "$RPATH"
			[ "$?" != "0" ] && error
		else 	syslinux "${IMAGE}"
			[ "$?" != "0" ] && error
        	fi 

        fi
	if [ "$BOOTLOADER" = "grub" ]
        then	mkdir -p "${RPATH}/boot/newgrub/grub" 
                grub-install --force \
                --allow-floppy \
                --boot-directory="${RPATH}/boot/newgrub/"  \
                --modules="ext2 part_msdos linux" \
                "${LOOP1}"

		[ "$?" != "0" ] && error
                
        fi 
fi

# Decompress and unarchive 
if [ $RESTORE = "1" -o $REMASTER = "1" ]
then 	
	cdwrap "$RPATH" 

	if [ "$QUICKTEST" = "1" ]
	then
		cp -r /boot .
		cp -r /lib .
		cp -r /lib64 .
		ln -s /boot/vmlinuz* vmlinuz
		ln -s /boot/initrd* initrd.img
	fi
	if [ "$QUICKTEST" = "0" ]
	then
       		if [ "$ARCV" = "iso" ]
       		then    "$COMPRESSION" -d "${START}/${TARBALL}"
       	        	 xorriso -osirrox on -indev "${START}/${NAME}.${ARCV}" -extract / .
       		else
                	"$COMPRESSION" -d --stdout "${START}/${TARBALL}" | $UNARCHIVE
       		fi
	fi
        cdwrap "${START}"
fi

# Remastery stage 2 ( configuration files )
if [ $REMASTER = "1" ]
then 
	cdwrap "$RPATH" 

	# Use dhcp-client at startup:
	if [ -e etc/network/interfaces ]
	then 	cp etc/network/interfaces etc/network/interfaces.last
	fi
	echo "auto lo" > etc/network/interfaces 
	echo "iface lo inet loopback" >> etc/network/interfaces 
	echo "allow-hotplug eth0" >> etc/network/interfaces 
	echo "iface eth0 inet dhcp" >> etc/network/interfaces

	# Overide the fstab to use the binary.img as / 
	if [ -e etc/fstab ]
        then    cp etc/fstab etc/fstab.last
        fi 
	DEVICE="/dev/sda1"
	echo "$DEVICE / $FS errors=remount-ro 0 1" > etc/fstab 
	echo "tmpfs /tmp tmpfs defaults 0 0"       >> etc/fstab 
	echo "proc /proc proc defaults 0 0"        >> etc/fstab
	mkdir -p proc tmp sys dev/shm boot 

	
	# Attempt to locate the distro's symlink to, or name of
	# the current kernel
	
	KERNEL=""
	INITRD="" 
	
	for i in  boot/* *
	do
        	case "$i" in
        	vmlinuz)
                	printf "found '%s'\n" "$i"
       	         	KERNEL="/$i"
                	;;
        	boot/vmlinuz)
                	printf "found '%s'\n" "$i"
                	KERNEL="/$i"
                	;;
		bzImage)
                        printf "found '%s'\n" "$i"
                        KERNEL="/$i"
                        ;;
                boot/bzImage)
                        printf "found '%s'\n" "$i"
                        KERNEL="/$i"
                        ;;
        	initrd.img)
                	printf "found '%s'\n" "$i"
                	INITRD="/$i"
                	;;
        	boot/initrd.img) 
			printf "found '%s'\n" "$i"
                	INITRD="/$i"
                	;;
       	 	esac
	done 


	if ! [ -z "$KERNEL" ]
	then   	printf "kernel set as '%s'\n"  "$KERNEL"
	else    printf "kernel not set\n"
		printf "Unable to configure bootloader, remastery failed. exiting..\n" 
        	# error 
	fi

	if ! [ -z "$INITRD" ]
	then 	printf "initrd set as '%s'\n" "$INITRD"
	else  	printf "initrd not set\n"
	fi 
	
	# syslinux configuration file
	if [ "$BOOTLOADER" = "syslinux" ]
        then
		#cp /usr/lib/syslinux/vesamenu.c32 .
		cp /usr/lib/syslinux/menu.c32 .
		LOADERCONF="syslinux.cfg" 
		echo > "${LOADERCONF}"
		echo "MENU COLOR screen 30;40   #40000000 #00000000 std" >> "${LOADERCONF}"
		echo "MENU COLOR title  37;40   #40000000 #00000000 std" >> "${LOADERCONF}"
		echo "MENU COLOR border 30;40   #40000000 #00000000 std" >> "${LOADERCONF}"
		echo "MENU COLOR unsel  37;40   #40000000 #00000000 std" >> "${LOADERCONF}"
		echo "MENU COLOR sel    7;37;40 #e0000000 #20ff8000 all" >> "${LOADERCONF}"

		#printf "UI vesamenu.c32\n" >> "${LOADERCONF}" 
		echo "UI menu.c32"      >> "${LOADERCONF}"
		echo "DEFAULT linux"    >> "${LOADERCONF}"
		echo "TIMEOUT 0"        >> "${LOADERCONF}"
		echo "PROMPT 0"         >> "${LOADERCONF}"
		echo "LABEL ${TITLE}"   >> "${LOADERCONF}" 
		echo "kernel ${KERNEL}" >> "${LOADERCONF}"
		
		echo -n "APPEND "       >> "${LOADERCONF}"
		if ! [ -z "$INITRD" ]
		then 	echo -n "initrd=${INITRD} " >> "${LOADERCONF}"
		fi 
		echo "root=${DEVICE}"   >> "${LOADERCONF}" 
	fi

	# grub configuration file
	if [ "$BOOTLOADER" = "grub" ]
        then
		mkdir -p boot/newgrub/grub 
		LOADERCONF="boot/newgrub/grub/grub.cfg"
		printf "set timeout=5\n" >> "${LOADERCONF}" 
		printf "menuentry \"${TITLE}\" {\n" >> "${LOADERCONF}" 
		printf "set root=(hd0,msdos1)\n" >> "${LOADERCONF}"
		printf "linux %s " "${KERNEL}">> "${LOADERCONF}"
		if ! [ -z "$INITRD" ]
		then
			printf "initrd=%s " "${INITRD}" >> "${LOADERCONF}" 
		fi
		printf "root=%s \n" "${DEVICE}" >> "${LOADERCONF}"
		if ! [ -z "$INITRD" ]
                then 	printf "initrd %s " "${INITRD}" >> "${LOADERCONF}" 
		fi
		printf "}\n" >> "${LOADERCONF}" 
	fi

	cdwrap "${START}" 

	# Unmount everything
	unmount 

fi 

if [ $TEST = "1" ]
then 	# Test a remastered image
        kvm -m 500 "${IMAGE}"
fi


