#!/bin/bash
######################################################
#
# Zip, Copy, Clean Up
# Zips loaner user data, copies it to the remote share,
# removes both zipped and original data.
# written by Eric Fisher
#
# Revisions
# 1.0  - 1 OCT 2013
# 
#
######################################################

# These are static variables, e.g. serial number, absolute pathnames, etc.
##########################################################################
TODAY=$(date +%F)
SERIAL_NUM=$(system_profiler SPHardwareDataType | grep "Serial Number" | cut -d " " -f 10)
LDATA="/Users/loaner"
SERVER="/Volumes/Archer"
FOLDER="loaner_backups"
USER_LIB_PATH="${LDATA}/Library"
LIB_TEMP_PATH="/tmp/bass_library"
ALERT=""

# These are dynamic variables, e.g. zipped file name.
#####################################################
USER=$1
ZIP_NAME="${SERIAL_NUM}.${USER}.${TODAY}.tgz"
LOCAL_PATH="/Users/${ZIP_NAME}"
REMOTE_PATH="${SERVER}/${FOLDER}/${ZIP_NAME}"
LIB_PATH=$2
DIR=$3
PIC_PATH=$4

# Tars/zips the loaner user folder.
###################################
function zipLoaner {
	if [[ -d ${LDATA} ]]
	then
		tar -czf ${ZIP_NAME} "loaner"
	else
		ALERT="Loaner\ user\ folder\ does\ not\ exist."
		echo ${ALERT}
	fi
}

# Copies zipped loaner to remote share.
#######################################
function copyData {
	if [[ -e "${ZIP_NAME}" ]]
	then
		cp -f ${ZIP_NAME} ${SERVER}/${FOLDER}
	else
		ALERT="Copy\ of\ loaner\ data\ failed.\ Relaunch\ the\ app\ and\ retry."
		echo ${ALERT}
	fi
}

# Compares sizes between original zipped and copied zipped.  Cleans up if size matches.
#######################################################################################
function cleanUp {
	LOCAL_SIZE=$(du -h ${LOCAL_PATH} | awk '{print $1}')
	REMOTE_SIZE=$(du -h ${REMOTE_PATH} | awk '{print $1}')
	if [[ ${REMOTE_SIZE} == ${LOCAL_SIZE} ]]
	then
		umount ${SERVER}
		rm ${ZIP_NAME}
		rm -r ${LDATA}
	else
		ALERT="Clean\ up\ failed.\ Remove\ files\ manually\ or\ relaunch\ the\ app."
		echo ${ALERT}
	fi
}

# Makes a new loaner user folder and subfolders.
################################################
function mkLoaner {
	if [[ ! -a ${LDATA} ]]
	then
		mkdir -p ${LDATA}/{Applications,Desktop,Documents,Downloads,Library,Movies,Music,Pictures,Public}
	else
		ALERT="Unable\ to\ create\ new\ loaner\ user\ folder.\ Create\ it\ manually\ or\ relaunch."
		echo ${ALERT}
	fi
}

function copyLib {
	if [[ -a ${USER_LIB_PATH} ]]
	then
		mkdir ${LIB_TEMP_PATH}
		tar -xzf ${LIB_PATH} -C ${LIB_TEMP_PATH}
		ditto ${LIB_TEMP_PATH}/Library ${USER_LIB_PATH}
		cp -f ${PIC_PATH} ${LDATA}/Pictures
		sudo chown -R loaner ${LDATA}
		chmod -R u=rwX ${LDATA}
		chflags hidden ${USER_LIB_PATH} 
		rm -r ${LIB_TEMP_PATH}
	else
		ALERT="Unable\ to\ copy\ user\ library.\  Relaunch\ and\ retry."
		echo ${ALERT}
	fi
}

cd /Users
zipLoaner > >(${DIR}/Contents/MacOS/CocoaDialog progressbar --title "Bass: Compression In Progress" --text "Step 1 of 4: Compressing loaner data.  This may take a while..."  --indeterminate)
copyData > >(${DIR}/Contents/MacOS/CocoaDialog progressbar --title "Bass: Copy In Progress" --text "Step 2 of 4: Copying backup to server.  Could be a bit..."  --indeterminate)
cleanUp > >(${DIR}/Contents/MacOS/CocoaDialog progressbar --title "Bass: Clean Up In Progress" --text "Step 3 of 4: Cleaning up old data..."  --indeterminate)
mkLoaner
copyLib > >(${DIR}/Contents/MacOS/CocoaDialog progressbar --title "Bass: Creating New User" --text "Step 4 of 4: Creating new \"loaner\" user.  Almost done..."  --indeterminate)
if [[ -z ${ALERT} ]]
then
	ALERT="All good."
	echo ${ALERT}
	exit 0
fi