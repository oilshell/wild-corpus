#!/bin/bash
# This should not be considered a good idea in any measure...
# Also script assumes root privs
hash -r
set -e

port=8443   # what if already occupied?
if [[ $1 != "" ]]; then
    target=$1
else
    target=supermarket.chef.io
fi

if [[ $2 != "" ]]; then
    cafile=$2
else
    cafile=/opt/chef/embedded/ssl/cert.pem
fi

echo "Copying SSL certificate for $target into store $cafile"

if [[ -f ./proxy_setup.sh ]]; then
  . ./proxy_setup.sh
fi

apt-get install proxytunnel

proxytunnel -p ${https_proxy##*://} -d $target:443 -a ${port} &
pid=$!
trap 'kill ${pid}' HUP EXIT INT
sleep 1
#TODO: check for some sort of failure?
cp -H "${cafile}" "${cafile}.old"
echo | openssl s_client -connect 127.0.0.1:$port -showcerts | sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' >> "${cafile}"
