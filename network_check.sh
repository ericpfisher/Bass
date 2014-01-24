#!/bin/bash
#
# Network script
#
# v1.0
#
# written by Eric Fisher
#
# Summary: zips and copies loaner home folder to server, then recreates home folder
#
#
#
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/internals.sh

function networkCheck {
	if [[ -z $(ifconfig en0 | grep inet | cut -d " " -f 2) ]]
	then
		echo "Please check your ethernet connection"
		exit 1
	else
		pingtest=$(ping -c 1 $ARCHER | grep "% packet loss" | cut -d " " -f 7)
		if [[ "$pingtest" == "0.0%" ]]
		then
			connected="true"
		else
			connected=""
		fi
	fi
}

function mountArcher {
if [[ -z "$connected" ]]
then
	echo "Please check your Ethernet connection."
	exit 1
else
	mkdir /Volumes/Archer
	mount_afp afp://$USER:$PASS@$ARCHER/Archer /Volumes/Archer
	echo "Archer mounted."
fi
}


networkCheck
mountArcher