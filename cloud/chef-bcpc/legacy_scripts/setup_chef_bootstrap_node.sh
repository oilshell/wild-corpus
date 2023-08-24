#!/bin/bash

# Parameters : 
# $1 is the IP address of the bootstrap node
# $2 is the Chef environment name, default "Test-Laptop"

if [[ $# -ne 2 ]]; then
	echo "Usage: `basename $0` IP-Address Chef-Environment" >> /dev/stderr
	exit
fi

# Assume we are running in the chef-bcpc directory

HOSTNAME=`hostname -f`
knife client list | grep $HOSTNAME > /dev/null
RES=$?
if [[ "${RES}" -ne 0 ]]; then
    sudo bash -c 'EDITOR=true knife client create $(hostname -f) > /etc/chef/client.pem'
    knife actor map
    knife group add actor admins $(hostname -f)
else
    echo "$HOSTNAME already registered in Chef"
fi

# Are we running under Vagrant?  If so, jump through some extra hoops.
if [[ -d /home/vagrant ]]; then
  knife bootstrap -E $2 $1 -i /chef-bcpc-host/vbox/insecure_private_key -x vagrant --sudo
else
  knife bootstrap -E $2 $1 -x ubuntu --sudo
fi

knife node run_list add $(hostname -f) 'role[BCPC-Bootstrap]'
sudo chef-client
