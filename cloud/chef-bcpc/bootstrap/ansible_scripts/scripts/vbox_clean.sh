#!/bin/bash
# Exit immediately if anything goes wrong, instead of making things worse.
set -e

# destroy existing ansible BCPC VMs
candidate_list="ansible-bcpc-bootstrap ansible-bcpc-vm1 ansible-bcpc-vm2 ansible-bcpc-vm3 ansible-bcpc-vm4 ansible-bcpc-vm5 ansible-bcpc-vm6"
existing_vms=( $(VBoxManage list vms |  awk -v vmpattern="${candidate_list// /|}" '$1 ~ vmpattern {gsub(/"/,"",$1);print $1}') )
for VM in ${existing_vms[@]}; do
    VBoxManage controlvm $VM poweroff && true
    VBoxManage unregistervm $VM --delete
done
