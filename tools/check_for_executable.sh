#!/bin/sh

USERPATH="$1"

if ! [ -d "$USERPATH" ] 
then 	echo "$USERPATH not found"
	exit 1
fi 

for i in $USERPATH/* 
do	SWITCH="0"
	for j in $i/* $i/*/* $i/*/*/* $i/*/*/*/* $i/*/*/*/*/*
	do	
		[ -x "$j" ] && SWITCH="1"
	done
	if [ "$SWITCH" = "1" ]
	then 	
		echo -n ". "
	else	echo
		echo "$i NOT EXE BAD DIR DELETING IT!"
		rm -rf "$i"
	fi 
done 

echo

