#!/bin/sh

USERPATH="$1"
START="$(pwd)"


[ -d "$USERPATH" ] || { echo "$USERPATH not found" ; exit 1 ; }



for i in ${USERPATH}/*
do      
	cd "$i"
	pwd 
	rm static-linux-pkg
	for j in * */* */*/* */*/*/* */*/*/*/* */*/*/*/*/* */*/*/*/*/*/* */*/*/*/*/*/*/*
        do      if [ -f "$j" ]
		then	if [ -x "$j" ]
                	then 	echo "$j" >> static-linux-pkg
                        	echo "$j"
			fi
			#echo "$j" >> static-linux-pkg
			#echo "$j"
		fi
                
        done 
	echo
	echo
	cd "$START"
        
done

cd "$START"


