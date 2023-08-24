#!/bin/bash
#
# Script to instruct all cluster nodes to rerun chef client - useful,
# for example, after changing chef recipes on the chef server.
#
# This script uses cluster.txt to find cluster node definitions, see
# cluster-readme.txt for details
#

myping() {
    if  hash fping 2>/dev/null; then
        RES=`fping -aq $1`
    else
        RES=`ping -c 1 $1 | grep ttl`
    fi
    echo $RES
}
if [[ -z "$1" ]]; then
    echo "Usage: $0 environment (role)"
    exit
else
    ENVIRONMENT="$1"
fi
ROLE_REQUESTED="$2"
if [[ -f cluster.txt ]]; then
    while read HOSTNAME MACADDR IPADDR ILOIPADDR DOMAIN ROLE; do
        if [[ $HOSTNAME = "end" ]]; then
            continue
        fi
        if [[ -z "$ROLE_REQUESTED" || "$ROLE" = "$ROLE_REQUESTED"  ]]; then
            HOSTS="$HOSTS $HOSTNAME"
            IPS="$IPS $IPADDR"
        fi
    done < cluster.txt
    echo "HOSTS = $HOSTS"
    for HOST in $IPS; do
        RES=`myping $HOST`
        if [[ -z $RES ]]; then
            echo $HOST is down
            continue
        else
            echo $HOST is up
        fi
        ./nodessh.sh $ENVIRONMENT $HOST "chef-client" sudo
    done
fi

