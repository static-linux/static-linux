#!/bin/sh

USERPATH="$1"

[ -d "$USERPATH" ] || { echo "$USERPATH not found" ; exit 1 ; }

for i in $USERPATH/* 
do	#echo "$i"
	SWITCH="0"
	for j in $i/* $i/*/* $i/*/*/* $i/*/*/*/* $i/*/*/*/*/*
	do	#echo "$j"
		[ -x "$j" ] && SWITCH="1"
	done
	if [ "$SWITCH" = "1" ]
	then 	#echo "exe found!"
		echo -n ". "
	else	echo
		echo "$i NOT EXE BAD DIR DELETING IT!"
		rm -rf "$i"
	fi
	#echo new dir
done


echo
