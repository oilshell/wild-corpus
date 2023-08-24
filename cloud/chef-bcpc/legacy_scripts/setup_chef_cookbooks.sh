#!/bin/bash -e

# Expected to be run in the root of the Chef Git repository (e.g. chef-bcpc)

# TODO: extract chef organization
gen_knife_config(){
  cat <<EOF
current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                "admin"
client_key               "#{current_dir}/admin.pem"
validation_client_name   "bcpc-validator"
validation_key           "#{current_dir}/bcpc-validator.pem"
chef_server_url          "https://bcpc-bootstrap/organizations/bcpc"
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
cookbook_path            ["#{current_dir}/../cookbooks"]
EOF
}

copy_client_keys(){
  if [[ -n "$SUDO_USER" ]]; then
    OWNER=$SUDO_USER
  else
    OWNER=$USER
  fi

  install -d -m0770 -o $OWNER .chef
# TODO: this is just bad form...
  sudo install -m0600 -o $OWNER /etc/opscode/admin.pem .chef/admin.pem
  sudo install -m0600 -o $OWNER /etc/opscode/bcpc-validator.pem .chef/bcpc-validator.pem
}

set -x

PROXY_INFO_FILE="/home/vagrant/proxy_info.sh"
if [[ -f $PROXY_INFO_FILE ]]; then
  . $PROXY_INFO_FILE
fi

if [[ -f ./proxy_setup.sh ]]; then
  . ./proxy_setup.sh
fi

if [[ -z "$1" ]]; then
	BOOTSTRAP_IP=10.0.100.3
else
	BOOTSTRAP_IP=$1
fi

if [[ -z "$2" ]]; then
	USER=root
else
	USER=$2
fi

# make sure we do not have a previous .chef directory in place to allow re-runs
if [[ -f .chef/knife.rb ]]; then
  knife node delete `hostname -f` -y || true
  knife client delete $USER -y || true
  mv .chef/ ".chef_found_$(date +"%m-%d-%Y %H:%M:%S")"
fi

install -d -m0700 .chef
gen_knife_config > .chef/knife.rb
cp -p .chef/knife.rb .chef/knife-proxy.rb

if [[ ! -z "$http_proxy" ]]; then
  echo  "http_proxy  \"${http_proxy}\"" >> .chef/knife-proxy.rb
  echo "https_proxy \"${https_proxy}\"" >> .chef/knife-proxy.rb
fi

copy_client_keys

# TODO: Is this right place for this?
knife ssl fetch
cd cookbooks

# allow versions on cookbooks so 
for cookbook in "apt 1.10.0" ubuntu cron ntp "yum 3.2.2" "logrotate 1.6.0"; do
  if [[ ! -d ${cookbook% *} ]]; then
     # unless the proxy was defined this knife config will be the same as the one generated above
    knife cookbook site download $cookbook --config ../.chef/knife-proxy.rb
    tar zxf ${cookbook% *}*.tar.gz
    rm ${cookbook% *}*.tar.gz
    if [[ -f ${cookbook% *}.patch ]]; then
      pushd ${cookbook% *}
      patch -p1 < ../${cookbook% *}.patch
      popd
    fi
  fi
done
