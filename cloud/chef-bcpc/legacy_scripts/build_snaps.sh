#!/bin/bash
#
# Quick script to take snapshots after OS build.
# TODO: Rewrite me in ruby... the whole thing.
hash -r

wait_for_ssh(){
  local hostname="$1"
  local min=${2:-1} max=${3:-10}

  if [ -z "${hostname}" ] ; then return 1 ; fi
  exec 3>&2
  exec 2>/dev/null
  while true ; do
    if echo > /dev/tcp/${hostname}/22 ; then
      return 0
    fi
    sleep $(( $RANDOM % $max + $min ))
  done
  exec 2>&3
  exec 3>&-
}

wait_for_snapshot(){
  local ip="$1"
  if [ -z "${ip}" ] ; then
    return 1
  fi
  local vmname="$(ip_to_name ${ip})" || return 2
  echo "Waiting to snapshot ${vmname} at ${ip}..."
  wait_for_ssh "${ip}"
  VBoxManage snapshot "${vmname}" take build_completed --description "Base OS installed"
}

# This is highly presumptive
ip_to_name(){
  if [ -z "$1" ] ; then return 1 ; fi
  local l="${1##*.}"
  l=$((l-10))
  echo "bcpc-vm${l}"
}

for ip in 10.0.100.{11..13} ; do eval "wait_for_snapshot ${ip} &" ; done
wait
