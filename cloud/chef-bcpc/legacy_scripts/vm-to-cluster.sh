 #!/bin/bash
#
# Script to help making a cluster definition file (cluster.txt) from
# the current VMs known by VirtualBox. This is intended to be run on
# the hypervisor as it relies on using the VBoxManage tool
#
# cluster.txt can be used by the cluster-*.sh tools for various
# cluster automation tasks, see cluster-readme.txt
#

# bash imports
source ./virtualbox_env.sh

if [[ -z "$1" ]]; then
        echo "Usage: $0 domain (environment)"
        exit
fi

DOMAIN="$1"
ENVIRONMENT="$2"

function getvminfo {
    
    HOSTNAME="$1"

    # extract the first mac address for this VM
    MAC1=`$VBM showvminfo $HOSTNAME --machinereadable | grep macaddress1 | tr -d \" | tr = " " | awk '{print $2}'`
    # add the customary colons in
    MAC1=`echo $MAC1 | sed -e 's/^\([0-9A-Fa-f]\{2\}\)/\1_/'  \
        -e 's/_\([0-9A-Fa-f]\{2\}\)/:\1_/' \
        -e 's/_\([0-9A-Fa-f]\{2\}\)/:\1_/' \
        -e 's/_\([0-9A-Fa-f]\{2\}\)/:\1_/' \
        -e 's/_\([0-9A-Fa-f]\{2\}\)/:\1_/' \
        -e 's/_\([0-9A-Fa-f]\{2\}\)/:\1/'`
    
    IP=`sshpass -p ubuntu ssh ubuntu@10.0.100.3 "arp | grep -i $MAC1 | cut -f1 -d\" \""`
    
    
    # there's no IP address for the ILO for VMs, instead use
    # VirtualBox's graphical console
    ILOIPADDR="-"
    
    # We can deduce roles only for the standard pattern recommended
    # for the Test-Laptop sample virtual machine cluster build
    if [[ "$ENVIRONMENT" = "Test-Laptop" ]]; then
        if [[ "$HOSTNAME" = "bcpc-vm1" ]]; then
            ROLE="head"
        elif [[ "$HOSTNAME" = "bcpc-vm2" || "$HOSTNAME" = "bcpc-vm3" ]]; then
            ROLE="work"
        elif [[ "$HOSTNAME" = "bcpc-bootstrap" ]]; then
            BOOTSTRAPIP="10.0.100.3"
            IP="$BOOTSTRAPIP"
            ROLE="bootstrap"
        else
            ROLE="unknown"
        fi
    fi
    echo "$HOSTNAME $MAC1 $IP $ILOIPADDR $DOMAIN $ROLE"
}

if [[ -f cluster.txt ]]; then
    echo "Found cluster.txt. Saved as cluster.txt.save$$"
    mv cluster.txt cluster.txt.save$$
    touch cluster.txt
fi

VMLIST=`$VBM list vms`
for V in $VMLIST; do
    if [[ ! "$V" =~ "{" ]]; then
        VM=`echo "$V" | awk '{print substr($0, 2, length() -2)}'`
        getvminfo $VM >> cluster.txt
    fi
done
echo "end" >> cluster.txt
if [[ "$ENVIRONMENT" = "Test-Laptop" ]]; then
    echo "cluster.txt created. Default roles for Test-Laptop have been assigned"
    sshpass -p ubuntu scp cluster.txt ubuntu@${BOOTSTRAPIP}:/home/ubuntu/chef-bcpc
else
    echo "cluster.txt created. Please assign roles"
fi
