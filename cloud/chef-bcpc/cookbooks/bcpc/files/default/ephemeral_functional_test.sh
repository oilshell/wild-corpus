#!/bin/bash
# This script creates a small logical volume in the given LVM volume group
# in order to detect problems with LVM or the underlying RAID 0 device
# (mdadm does not indicate problems with the array even when drives drop out).

LOG_TAG="`basename $0`"

function log {
	logger -t $LOG_TAG $1
}

if [[ "$1" == "" ]]; then
	echo "You must provide the path of a LVM volume group." >&2
	exit 100
fi

FAILED=0
START_TIME=$(date +%s.%N)
log "Beginning ephemeral functional test at ${START_TIME}"
LV_NAME=EphemeralFunctionalTest_$(uuidgen)
log "Creating LV ${LV_NAME} in VG $1"
# create a 4MB logical volume in the given volume group
LV_CREATION_OUTPUT=$(/sbin/lvcreate $1 -n ${LV_NAME} -L 4M -A n 2>&1)
CREATION_TIME=$(date +%s.%N)
log "LV ${LV_NAME} created in $(echo "${CREATION_TIME}-${START_TIME}" | bc -l) seconds"

if echo ${LV_CREATION_OUTPUT} | egrep -q '(Input/output error|read failed)'; then
	FAILED=1
fi

log "Ephemeral functional test result: ${LV_CREATION_OUTPUT}"

# attempt to clean up LV
/sbin/lvremove -f /dev/$1/${LV_NAME} -A n >/dev/null 2>&1
END_TIME=$(date +%s.%N)
log "LV ${LV_NAME} removed in $(echo "${END_TIME}-${CREATION_TIME}" | bc -l) seconds"
log "Duration of test: $(echo "${END_TIME}-${START_TIME}" | bc -l) seconds"
log "Completed ephemeral functional test at ${END_TIME}"

# according to kelvk, need to echo something here for Zabbix trigger expression to evaluate
echo $FAILED
exit $FAILED
