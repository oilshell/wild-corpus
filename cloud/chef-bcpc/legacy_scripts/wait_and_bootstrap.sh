#!/bin/bash

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

setup_headnodes(){
  # TODO: get name-ip mappings from somewhere else
  bootstrap_head bcpc-vm1.bcpc.example.com 10.0.100.11 || true
  local keyfile=~/.ssh/id_rsa.root
  if [ ! -r "${keyfile}" ] ; then
      ./install_root_key || keyfile=~/.ssh/id_rsa.bcpc
  fi
  echo "Proceeding with second chef-client run"
  ssh -i "${keyfile}" -lroot 10.0.100.11 chef-client
}

bootstrap_head(){
  local nodename="$1"
  local ip="$2"
  if [ -z "${ip}" -o -z "${nodename}" ] ; then return 1 ; fi
  time -p wait_for_ssh "${ip}"
  echo "Configuring temporary hosts entry for chef server on ${ip}"
  add_hosts_entries "${ip}" "${hosts_entries}"
  knife bootstrap --bootstrap-no-proxy "${chef_server_host}" ${bootstrap_proxy_args} \
    -i "${keyfile}" -x root --node-ssl-verify-mode=none \
    --bootstrap-wget-options "--no-check-certificate" \
    -r 'role[BCPC-Headnode]' -E Test-Laptop "${ip}" -N "${nodename}"
    knife actor map >&2
    knife group add actor admins "${nodename}" >&2
}

bootstrap_worker(){
  local nodename="$1"
  local ip="$2"
  if [ -z "${ip}" -o -z "${nodename}" ] ; then return 1 ; fi
  time -p wait_for_ssh "${ip}"
  echo "Configuring temporary hosts entry for chef server on ${ip}"
  add_hosts_entries "${ip}" "${hosts_entries}"
  knife bootstrap --bootstrap-no-proxy "${chef_server_host}" ${bootstrap_proxy_args} \
    -i "${keyfile}" -x root \
    --bootstrap-wget-options "--no-check-certificate" \
    -r 'role[BCPC-Worknode]' -E Test-Laptop "$ip" -N "${nodename}"
}

# $1 - destination_ip
# $2 - entries
add_hosts_entries(){
  local ip="$1" entries="$2"
  if [ -z "${ip}" -o -z "${entries}" ] ; then return 1 ; fi
  echo $entries
  ssh -ostricthostkeychecking=no -i "${keyfile}" -lroot "${ip}" <<EoF
  if ! getent ahosts bcpc-bootstrap &> /dev/null ; then
  cat <<EoS >> /etc/hosts
# Added by ${0##*/}
$entries
EoS
  fi
  getent hosts bcpc-bootstrap
EoF
}

configure_proxy(){
  if [[ -f ./proxy_setup.sh ]]; then
    . ./proxy_setup.sh
    export -n http{,s}_proxy  # do not interfere with subsequent calls to knife
  fi
  if [[ -n "${https_proxy}" ]] ; then
    bootstrap_proxy_args="--bootstrap-proxy ${https_proxy}"
  else
    bootstrap_proxy_args=""
  fi
}

# Quick hack to determine name from ip
ip_to_name(){
  local ip="$1"
  # prefer over ${ip##*.} for easier validation
  IFS='.' read _ _ _ nodenum <<EoF
$ip
EoF
  if [ -z "${ip}" -o -z "${nodenum}" ] ; then return 1 ; fi
  local suffix=$((nodenum - 10))
  echo bcpc-vm${suffix}.${domainname}
}

domainname=bcpc.example.com
chef_server_host=bcpc-bootstrap
keyfile=~/.ssh/id_rsa.bcpc
hosts_entries="\
10.0.100.3 ${chef_server_host}
"

set -e
configure_proxy
setup_headnodes

echo "Waiting to bootstrap workers"
set -x
for ip in 10.0.100.{12..13} ; do eval "bootstrap_worker "$(ip_to_name ${ip})" ${ip} &" ; done
wait
