#!/bin/bash
# Script to assign roles to cluster nodes based on a definition in cluster.txt :
#
# - If no hostname is provided, all nodes will be attempted
#
# - if a nodename is provided, either by hostname or ip address, only
#   that node will be attempted
#
# - if the special nodename "heads" is given, all head nodes will be
#   attempted
#
# - if the special nodename "workers" is given, all work nodes will be
#   attempted
#
# - A node may be excluded by setting its role to something other than
#   "head" or "work" in cluster.txt. For example "done" might be
#   useful for nodes that have been completed
set -e
if [[ -z "$1" ]]; then
    echo "Usage : $0 environment (hostname)"
    exit 1
fi

ENVIRONMENT=$1
EXACTHOST=$2

if [[ ! -f "environments/$ENVIRONMENT.json" ]]; then
    echo "Error: Couldn't find '$ENVIRONMENT.json'. Did you forget to pass the environment as first param?"
    exit 1
fi

declare -A FQDNS

while read HOST MACADDR IPADDR ILOIPADDR DOMAIN ROLE; do
    if [[ -z "$EXACTHOST" || "$EXACTHOST" = all || "$EXACTHOST" = "$HOST" || "$EXACTHOST" = "$IPADDR" || "$EXACTHOST" = "heads" && "$ROLE" = "head" || "$EXACTHOST" = "workers" && "$ROLE" = "work" ]]; then
        IDX=`echo $IPADDR | tr '.' '-'`
        if [[ "$ROLE" = "bootstrap" ]]; then
            continue
        fi
        if   [[ "$ROLE" = head ]]; then
            HEADS="$HEADS $IPADDR"
            FQDNS["$IDX"]="${HOST}.${DOMAIN}"
        elif [[ "$ROLE" = work ]]; then
            WORKERS="$WORKERS $IPADDR"
            FQDNS["$IDX"]="${HOST}.${DOMAIN}"
        fi  
    fi
done < cluster.txt
echo "heads : $HEADS"
echo "workers : $WORKERS"

PASSWD=`knife data bag show configs $ENVIRONMENT | grep "cobbler-root-password:" | awk ' {print $2}'`
# All nodes now use an unbundled initialisation - chef is installed from
# a .deb (allowing disconnected working) and then the node is
# bootstrapped with no role to start, and then it is made admin, and
# then the role is assigned, finally chef-client is run
for HEAD in $HEADS; do
    MATCH=$HEAD
    echo "About to bootstrap head node $HEAD..."
    ./chefit.sh $HEAD $ENVIRONMENT
    echo $PASSWD | sudo knife bootstrap -E $ENVIRONMENT $HEAD -x ubuntu  -P $PASSWD --sudo
    IDX=`echo $HEAD | tr '.' '-'`
    FQDN=${FQDNS["$IDX"]}
    knife actor map
    knife group add actor admins $FQDN
    knife node run_list add $FQDN 'role[BCPC-Headnode]'
    SSHCMD="./nodessh.sh $ENVIRONMENT $HEAD"
    $SSHCMD "/home/ubuntu/finish-head.sh" sudo  
done
# As of R5, we seem to need to use the two-step bootstrap for work nodes too
for WORKER in $WORKERS; do
    MATCH=$WORKER
    echo "About to bootstrap worker worker $WORKER..."
    ./chefit.sh $WORKER $ENVIRONMENT
    echo $PASSWD | sudo knife bootstrap -E $ENVIRONMENT $WORKER -x ubuntu -P $PASSWD --sudo
    IDX=`echo $WORKER | tr '.' '-'`
    FQDN=${FQDNS["$IDX"]}
    knife actor map
    knife group add actor admins $FQDN
    knife node run_list add $FQDN 'role[BCPC-Worknode]'
    SSHCMD="./nodessh.sh $ENVIRONMENT $WORKER"
    $SSHCMD "/home/ubuntu/finish-worker.sh" sudo    
done
if [[ -z "$MATCH" ]]; then
    echo "Warning: No nodes found"
fi

