#!/bin/bash

#
# This script expects to be run in the chef-bcpc directory with root under sudo
#

set -e

if [[ -f ./proxy_setup.sh ]]; then
  . ./proxy_setup.sh
fi

PROXY_INFO_FILE="/home/vagrant/proxy_info.sh"
if [[ -f $PROXY_INFO_FILE ]]; then
  . $PROXY_INFO_FILE
fi

# define calling gem with a proxy if necessary
if [[ -z $http_proxy ]]; then
    GEM_PROXY=""
else
    GEM_PROXY="-p $http_proxy"
fi

if [[ -z "$1" ]]; then
        BOOTSTRAP_IP=10.0.100.3
else
        BOOTSTRAP_IP=$1
fi

# needed within build_bins which we call
if [[ -z "$CURL" ]]; then
	echo "CURL is not defined"
	exit
fi

if dpkg -s chef-server-core 2>/dev/null | grep -q Status.*installed; then
  echo chef server is installed
else
  dpkg -i cookbooks/bcpc/files/default/bins/chef-server.deb
  if [ ! -s /etc/opscode/chef-server.rb ]; then
    if [ ! -d /etc/opscode ]; then
      mkdir /etc/opscode
      chown 775 /etc/opscode
    fi
    cat > /etc/opscode/chef-server.rb <<EOF
# api_fqdn "${BOOTSTRAP_IP}"
# allow connecting to http port directly
# nginx['enable_non_ssl'] = true
# have nginx listen on port 4000
nginx['non_ssl_port'] = 4000
# allow long-running recipes not to die with an error due to auth
#opscode_erchef['s3_url_ttl'] = 3600
EOF
  fi
  chef-server-ctl reconfigure
  chef-server-ctl user-create admin admin admin admin@localhost.com welcome --filename /etc/opscode/admin.pem
  chef-server-ctl org-create bcpc "BCPC" --association admin --filename /etc/opscode/bcpc-validator.pem
  chmod 0600 /etc/opscode/{bcpc-validator,admin}.pem
fi

dpkg -E -i cookbooks/bcpc/files/default/bins/chef-client.deb

# copy our ssh-key to be authorized for root
if [[ -f $HOME/.ssh/authorized_keys && ! -f /root/.ssh/authorized_keys ]]; then
  if [[ ! -d /root/.ssh ]]; then
    mkdir /root/.ssh
  fi
  cp $HOME/.ssh/authorized_keys /root/.ssh/authorized_keys
fi

echo "HTTP proxy: $http_proxy"
echo "HTTPS proxy: $https_proxy"

# Bad hack for finnicky MITM proxies...
if [[ -n "$https_proxy" ]] ; then
  ./proxy_cert_download_hack.sh rubygems.org
  ./proxy_cert_download_hack.sh supermarket.chef.io
fi

# install knife-acl plugin
read shebang < $(type -P knife)
ruby_interp="${shebang:2}"
bindir="${ruby_interp%/*}"
$bindir/gem install $GEM_PROXY knife-acl
