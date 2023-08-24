#!/bin/bash
# Exit immediately if anything goes wrong, instead of making things worse.
set -e

. $REPO_ROOT/bootstrap/shared/shared_functions.sh

################################################################################
# Function to remove VirtualBox DHCP servers
# By default, checks for any DHCP server on networks without VM's & removes them
# (expecting if a remove fails the function should bail)
# If a network is provided, removes that network's DHCP server
# (or passes the vboxmanage error and return code up to the caller)
# 
function remove_DHCPservers {
  local network_name=${1-}
  if [[ -z "$network_name" ]]; then
    # make a list of VM UUID's
    local vms=$(VBoxManage list vms|sed 's/^.*{\([0-9a-f-]*\)}/\1/')
    # make a list of networks (e.g. "vboxnet0 vboxnet1")
    local vm_networks=$(for vm in $vms; do \
      VBoxManage showvminfo --details --machinereadable $vm | \
      grep -i '^hostonlyadapter[2-9]=' | \
      sed -e 's/^.*=//' -e 's/"//g'; \
    done | sort -u)
    # will produce a regular expression string of networks which are in use by VMs
    # (e.g. ^vboxnet0$|^vboxnet1$)
    local existing_nets_reg_ex=$(sed -e 's/^/^/' -e 's/$/$/' -e 's/ /$|^/g' <<< "$vm_networks")

    VBoxManage list dhcpservers | grep -E "^NetworkName:\s+HostInterfaceNetworking" | awk '{print $2}' |
    while read -r network_name; do
      [[ -n $existing_nets_reg_ex ]] && ! egrep -q "$existing_nets_reg_ex" <<< $network_name && continue
      remove_DHCPservers $network_name
    done
  else
    VBoxManage dhcpserver remove --netname "$network_name" && local return=0 || local return=$?
    return $return
  fi
}

###################################################################
# Function to create all VMs using Vagrant
function create_vagrant_vms {
  cd $REPO_ROOT/bootstrap/vagrant_scripts && vagrant up
}

# only execute functions if being run and not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  remove_DHCPservers
  create_vagrant_vms
fi
