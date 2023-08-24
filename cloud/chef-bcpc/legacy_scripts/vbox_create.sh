#!/bin/bash -e

#### NOTE TO SELF SO I DON'T FORGET LATER: you can pass the name of an environment JSON file to this script
# (e.g., test-custom instead of Test-Laptop) to build using that one

# bash imports
source ./virtualbox_env.sh
if [[ -f ./vbox_override.sh ]]; then
    source ./vbox_override.sh
fi

if [[ "$OSTYPE" == msys || "$OSTYPE" == cygwin ]]; then
  WIN=TRUE
fi

set -x

if [[ -f ./proxy_setup.sh ]]; then
  . ./proxy_setup.sh
fi
if [[ -z "$CURL" ]]; then
  echo "CURL is not defined"
  exit
fi

# Bootstrap VM Defaults (these need to be exported for Vagrant's Vagrantfile)
# DO NOT EDIT THESE HERE, INSTEAD EDIT THEM IN vbox_override.sh
export BOOTSTRAP_APT_MIRROR=${BOOTSTRAP_APT_MIRROR:-}
export BOOTSTRAP_VM_MEM=${BOOTSTRAP_VM_MEM:-2048}
export BOOTSTRAP_VM_CPUS=${BOOTSTRAP_VM_CPUS:-1}
export BOOTSTRAP_VM_DRIVE_SIZE=${BOOTSTRAP_VM_DRIVE_SIZE:-20480}
export CLUSTER_VM_MEM=${CLUSTER_VM_MEM:-2560}
export CLUSTER_VM_CPUS=${CLUSTER_VM_CPUS:-2}
export CLUSTER_VM_DRIVE_SIZE=${CLUSTER_VM_DRIVE_SIZE:-20480}

BASE_DIR=`dirname ${BASH_SOURCE[0]}`
VBOX_DIR="$BASE_DIR/vbox"
P="$(cd $VBOX_DIR ; /bin/pwd)" || exit

# from EVW packer branch
vbm_import() {
    local -r image_name="$1"
    local -r vm_name="$2"
    shift 2
    # this currently assumes that only one virtual system is imported
    "$VBM" import "$image_name" --vsys 0 --vmname "$vm_name" "$@"
}

######################################################
# Function to download files necessary for VM stand-up
# 
function download_VM_files {
  pushd $P

  ROM=gpxe-1.0.1-80861004.rom
  CACHEDIR=~/bcpc-cache

  if [[ ! -f $ROM ]]; then
      if [[ -f $CACHEDIR/$ROM ]]; then
	  cp $CACHEDIR/$ROM .
      else
	  $CURL -o gpxe-1.0.1-80861004.rom "http://rom-o-matic.net/gpxe/gpxe-1.0.1/contrib/rom-o-matic/build.php" -H "Origin: http://rom-o-matic.net" -H "Host: rom-o-matic.net" -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -H "Referer: http://rom-o-matic.net/gpxe/gpxe-1.0.1/contrib/rom-o-matic/build.php" -H "Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.3" --data "version=1.0.1&use_flags=1&ofmt=ROM+binary+%28flashable%29+image+%28.rom%29&nic=all-drivers&pci_vendor_code=8086&pci_device_code=1004&PRODUCT_NAME=&PRODUCT_SHORT_NAME=gPXE&CONSOLE_PCBIOS=on&BANNER_TIMEOUT=20&NET_PROTO_IPV4=on&COMCONSOLE=0x3F8&COMSPEED=115200&COMDATA=8&COMPARITY=0&COMSTOP=1&DOWNLOAD_PROTO_TFTP=on&DNS_RESOLVER=on&NMB_RESOLVER=off&IMAGE_ELF=on&IMAGE_NBI=on&IMAGE_MULTIBOOT=on&IMAGE_PXE=on&IMAGE_SCRIPT=on&IMAGE_BZIMAGE=on&IMAGE_COMBOOT=on&AUTOBOOT_CMD=on&NVO_CMD=on&CONFIG_CMD=on&IFMGMT_CMD=on&IWMGMT_CMD=on&ROUTE_CMD=on&IMAGE_CMD=on&DHCP_CMD=on&SANBOOT_CMD=on&LOGIN_CMD=on&embedded_script=&A=Get+Image"
	      
      fi
      if [[ -d $CACHEDIR && ! -f $CACHEDIR/$ROM ]]; then
	  cp $ROM $CACHEDIR/$ROM
      fi
  fi

  ISO=ubuntu-14.04-mini.iso

  # Grab the Ubuntu installer image
  if [[ ! -f  $ISO ]]; then
      if [[ -f $CACHEDIR/$ISO ]]; then
	  cp $CACHEDIR/$ISO .
      else
	  #$CURL -o $ISO http://archive.ubuntu.com/ubuntu/dists/trusty/main/installer-amd64/current/images/netboot/mini.iso
	  $CURL -o $ISO http://archive.ubuntu.com/ubuntu/dists/trusty-updates/main/installer-amd64/current/images/netboot/mini.iso
      fi
      if [[ -d $CACHEDIR && ! -f $CACHEDIR/$ISO ]]; then
	  cp $ISO $CACHEDIR
      fi
  fi

  BOX='trusty-server-cloudimg-amd64-vagrant-disk1.box'

  # Can we create the bootstrap VM via Vagrant
  if hash vagrant 2> /dev/null ; then
    echo "Vagrant detected - downloading Vagrant box for bcpc-bootstrap VM"
    if [[ ! -f $BOX ]]; then
	if [[ -f $CACHEDIR/$BOX ]]; then
	    cp $CACHEDIR/$BOX .
	else
	    $CURL -o $BOX http://cloud-images.ubuntu.com/vagrant/trusty/current/$BOX
	fi
	if [[ -d $CACHEDIR && ! -f $CACHEDIR/$BOX ]]; then
	    cp $BOX $CACHEDIR
	fi
    fi
  fi

  popd
}

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
    local vms=$($VBM list vms|sed 's/^.*{\([0-9a-f-]*\)}/\1/')
    # make a list of networks (e.g. "vobxnet0 vboxnet1")
    local vm_networks=$(for vm in $vms; do \
                          $VBM showvminfo --details --machinereadable $vm | \
                          grep -i '^hostonlyadapter[2-9]=' | \
                          sed -e 's/^.*=//' -e 's/"//g'; \
                        done | sort -u)
    # will produce a regular expression string of networks which are in use by VMs
    # (e.g. ^vboxnet0$|^vboxnet1$)
    local existing_nets_reg_ex=$(sed -e 's/^/^/' -e '/$/$/' -e 's/ /$|^/g' <<< "$vm_networks")

    $VBM list dhcpservers | grep -E "^NetworkName:\s+HostInterfaceNetworking" | awk '{print $2}' |
    while read -r network_name; do
      [[ -n $existing_nets_reg_ex ]] && ! egrep -q $existing_nets_reg_ex <<< $network_name && continue
      remove_DHCPservers $network_name
    done
  else
    $VBM dhcpserver remove --netname "$network_name" && local return=0 || local return=$?
    return $return
  fi
}

###################################################################
# Function to create the bootstrap VM
# uses Vagrant or stands-up the VM in VirtualBox for manual install
# 
function create_bootstrap_VM {
  pushd $P

  remove_DHCPservers

  if hash vagrant 2> /dev/null ; then
    echo "Vagrant detected - using Vagrant to initialize bcpc-bootstrap VM"
    cp ../Vagrantfile .
    vagrant up
    keyfile="$(vagrant ssh-config bootstrap | awk '/Host bootstrap/,/^$/{ if ($0 ~ /^ +IdentityFile/) print $2}')"
    if [[ -f "$keyfile" ]]; then
      cp "$keyfile" insecure_private_key
    fi
  else
    echo "Vagrant not detected - using raw VirtualBox for bcpc-bootstrap"
    if [[ -z "$WIN" ]]; then
      # Make the three BCPC networks we'll need, but clear all nets and dhcpservers first
      for i in 0 1 2 3 4 5 6 7 8 9; do
        if [[ ! -z `$VBM list hostonlyifs | grep vboxnet$i | cut -f2 -d" "` ]]; then
          $VBM hostonlyif remove vboxnet$i || true
        fi
      done    
    else
      # On Windows the first interface has no number
      # The second interface is #2
      # Remove in reverse to avoid substring matching issue
      for i in 10 9 8 7 6 5 4 3 2 1; do
        if [[ i -gt 1 ]]; then
          IF="VirtualBox Host-Only Ethernet Adapter #$i";
        else
          IF="VirtualBox Host-Only Ethernet Adapter";
        fi
        if [[ ! -z `$VBM list hostonlyifs | grep "$IF"` ]]; then
          $VBM hostonlyif remove "$IF"
        fi
      done
    fi
  
    $VBM hostonlyif create
    $VBM hostonlyif create
    $VBM hostonlyif create
  
    if [[ -z "$WIN" ]]; then
      remove_DHCPservers vboxnet0 || true
      remove_DHCPservers vboxnet1 || true
      remove_DHCPservers vboxnet2 || true
      # use variable names to refer to our three interfaces to disturb
      # the remaining code that refers to these as little as possible -
      # the names are compact on Unix :
      VBN0=vboxnet0
      VBN1=vboxnet1
      VBN2=vboxnet2
    else
      # However, the names are verbose on Windows :
      VBN0="VirtualBox Host-Only Ethernet Adapter"
      VBN1="VirtualBox Host-Only Ethernet Adapter #2"
      VBN2="VirtualBox Host-Only Ethernet Adapter #3"
    fi

    $VBM hostonlyif ipconfig "$VBN0" --ip 10.0.100.2    --netmask 255.255.255.0
    $VBM hostonlyif ipconfig "$VBN1" --ip 172.16.100.2  --netmask 255.255.255.0
    $VBM hostonlyif ipconfig "$VBN2" --ip 192.168.100.2 --netmask 255.255.255.0

    # Create bootstrap VM
    for vm in bcpc-bootstrap; do
        # Only if VM doesn't exist
        if ! $VBM list vms | grep "^\"${vm}\"" ; then

            # define this if you have a pre-built OVA image
            # (virtualbox exported machine image), for example as
            # built by
            # https://github.com/ericvw/chef-bcpc/tree/packer/bootstrap
            ARCHIVED_BOOTSTRAP=../images/build/virtualbox/bcpc-bootstrap/packer-bcpc-bootstrap_ubuntu-14.04.2-amd64.ova

            if [[ -n "$ARCHIVED_BOOTSTRAP" && -f "$ARCHIVED_BOOTSTRAP" ]]; then
                vbm_import "$ARCHIVED_BOOTSTRAP" bcpc-bootstrap
            else
exit
                $VBM createvm --name $vm --ostype Ubuntu_64 --basefolder $P --register
                $VBM modifyvm $vm --memory $BOOTSTRAP_VM_MEM
                $VBM modifyvm $vm --cpus $BOOTSTRAP_VM_CPUS
                $VBM modifyvm $vm --vram 16
                $VBM storagectl $vm --name "SATA Controller" --add sata
                $VBM storagectl $vm --name "IDE Controller" --add ide
                # Create a number of hard disks
                port=0
                for disk in a; do
                    $VBM createhd --filename $P/$vm/$vm-$disk.vdi --size $BOOTSTRAP_VM_DRIVE_SIZE
                    $VBM storageattach $vm --storagectl "SATA Controller" --device 0 --port $port --type hdd --medium $P/$vm/$vm-$disk.vdi
                    port=$((port+1))
                done
                # Add the bootable mini ISO for installing Ubuntu ISO
                $VBM storageattach $vm --storagectl "IDE Controller" --device 0 --port 0 --type dvddrive --medium $ISO
                $VBM modifyvm $vm --boot1 disk
            fi
            # Add the network interfaces
            $VBM modifyvm $vm --nic1 nat
            $VBM modifyvm $vm --nic2 hostonly --hostonlyadapter2 "$VBN0"
            $VBM modifyvm $vm --nic3 hostonly --hostonlyadapter3 "$VBN1"
            $VBM modifyvm $vm --nic4 hostonly --hostonlyadapter4 "$VBN2"
        fi
    done
        fi
        popd
}

###################################################################
# Function to create the BCPC cluster VMs
# 
function create_cluster_VMs {
  # Gather VirtualBox networks in use by bootstrap VM (Vagrant simply uses the first not in-use so have to see what was picked)
  oifs="$IFS"
  IFS=$'\n'
  bootstrap_interfaces=($($VBM showvminfo bcpc-bootstrap --machinereadable|egrep '^hostonlyadapter[0-9]=' |sort|sed -e 's/.*=//' -e 's/"//g'))
  IFS="$oifs"
  VBN0="${bootstrap_interfaces[0]}"
  VBN1="${bootstrap_interfaces[1]}"
  VBN2="${bootstrap_interfaces[2]}"

  # Create each VM
  for vm in bcpc-vm1 bcpc-vm2 bcpc-vm3; do
      # Only if VM doesn't exist
      if ! $VBM list vms | grep "^\"${vm}\"" ; then
          $VBM createvm --name $vm --ostype Ubuntu_64 --basefolder $P --register
          $VBM modifyvm $vm --memory $CLUSTER_VM_MEM
          $VBM modifyvm $vm --cpus $CLUSTER_VM_CPUS
          $VBM modifyvm $vm --vram 16
          $VBM storagectl $vm --name "SATA Controller" --add sata
          # Create a number of hard disks
          port=0
          for disk in a b c d e; do
              $VBM createhd --filename $P/$vm/$vm-$disk.vdi --size $CLUSTER_VM_DRIVE_SIZE
              $VBM storageattach $vm --storagectl "SATA Controller" --device 0 --port $port --type hdd --medium $P/$vm/$vm-$disk.vdi
              port=$((port+1))
          done
          # Add the network interfaces
          $VBM modifyvm $vm --nic1 hostonly --hostonlyadapter1 "$VBN0" --nictype1 82543GC
          $VBM setextradata $vm VBoxInternal/Devices/pcbios/0/Config/LanBootRom $P/gpxe-1.0.1-80861004.rom
          $VBM modifyvm $vm --nic2 hostonly --hostonlyadapter2 "$VBN1"
          $VBM modifyvm $vm --nic3 hostonly --hostonlyadapter3 "$VBN2"

          # Set hardware acceleration options
          $VBM modifyvm $vm --largepages on --vtxvpid on --hwvirtex on --nestedpaging on --ioapic off
      fi
  done
}

function install_cluster {
environment=${1-Test-Laptop}
ip=${2-10.0.100.3}
  # VMs are now created - if we are using Vagrant, finish the install process.
  if hash vagrant 2> /dev/null ; then
    # N.B. As of Aug 2013, grub-pc gets confused and wants to prompt re: 3-way
    # merge.  Sigh.
    #vagrant ssh -c "sudo ucf -p /etc/default/grub"
    #vagrant ssh -c "sudo ucfr -p grub-pc /etc/default/grub"
    vagrant ssh -c "test -f /etc/default/grub.ucf-dist && sudo mv /etc/default/grub.ucf-dist /etc/default/grub" || true
    # Duplicate what d-i's apt-setup generators/50mirror does when set in preseed
    if [ -n "$http_proxy" ]; then
      if ! vagrant ssh -c "grep -z '^Acquire::http::Proxy ' /etc/apt/apt.conf"; then
        vagrant ssh -c "echo 'Acquire::http::Proxy \"$http_proxy\";' | sudo tee -a /etc/apt/apt.conf"
      fi

      # write the proxy to a known absolute location on the filesystem so that it can be sourced by build_bins.sh (and maybe other things)
      PROXY_INFO_SH="/home/vagrant/proxy_info.sh"
      if ! vagrant ssh -c "test -f $PROXY_INFO_SH"; then
        vagrant ssh -c "echo -e 'export http_proxy=$http_proxy\nexport https_proxy=$https_proxy' | sudo tee -a $PROXY_INFO_SH"
       fi
      CURLRC="/home/vagrant/.curlrc"
      if ! vagrant ssh -c "test -f $CURLRC"; then
        vagrant ssh -c "echo -e 'proxy = $http_proxy' | sudo tee -a $CURLRC"
      fi
      GITCONFIG="/home/vagrant/.gitconfig"
      if ! vagrant ssh -c "test -f $GITCONFIG"; then
        vagrant ssh -c "echo -e '[http]\nproxy = $http_proxy' | sudo tee -a $GITCONFIG"
      fi

      # copy any additional provided CA root certificates to the system store
      # note that these certificates must follow the restrictions of update-ca-certificates (i.e., end in .crt and be PEM)
      CUSTOM_BASE="custom"
      CUSTOM_CA_DIR="/usr/share/ca-certificates/$CUSTOM_BASE"
      for CERT in $(ls -1 $BASE_DIR/cacerts); do
        vagrant ssh -c "sudo mkdir -p $CUSTOM_CA_DIR"
        vagrant ssh -c "if [[ ! -f $CUSTOM_CA_DIR/$CERT ]]; then sudo cp /chef-bcpc-host/cacerts/$CERT $CUSTOM_CA_DIR/$CERT; fi"
        vagrant ssh -c "echo $CUSTOM_BASE/$CERT | sudo tee -a /etc/ca-certificates.conf"
      done
      vagrant ssh -c "sudo /usr/sbin/update-ca-certificates"
    fi
    echo "Bootstrap complete - setting up Chef server"
    echo "N.B. This may take approximately 30-45 minutes to complete."
    ./bootstrap_chef.sh --vagrant-remote $ip $environment
    ./enroll_cobbler.sh
  else
    ./non_vagrant_boot.sh
  fi
}

# only execute functions if being run and not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  download_VM_files
  create_bootstrap_VM
  create_cluster_VMs
  install_cluster $*
fi
