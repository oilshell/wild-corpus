#!/bin/bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright (c) 2014, Joyent, Inc.
#

#
# Marlin agent postinstall script: this is invoked after the Marlin package is
# installed to write out the SMF manifest and import the SMF service.  This is
# also invoked at build-time, but we don't do anything in that case.
#

if [[ -z "$npm_config_smfdir" || ! -d "$npm_config_smfdir" ]]; then
	echo "Skipping Marlin postinstall (assuming build-time install)"
	exit 0
fi

set -o xtrace

mpi_root=$(dirname $0)/..	 # root of Marlin installation
mpi_smfdir=$npm_config_smfdir	 # directory where SMF manifests go (from apm)
mpi_version=$npm_package_version # package version (from apm)

cd $mpi_root
mpi_root=$(pwd)
cd - > /dev/null

#
# Copy the SMF manifest bundled with this package to a directory whose
# manifests will be imported on system boot.  We also replace a few useful
# tokens in the manifest here.
#
sed -e "s#@@PREFIX@@#$mpi_root#g" -e "s/@@VERSION@@/$mpi_version/g" \
    "$mpi_root/smf/manifests/marlin-agent.xml" > "$mpi_smfdir/marlin-agent.xml"

#
# Import the manifest to start the service.
#
svccfg import $mpi_smfdir/marlin-agent.xml

#
# Check if we were enabled prior to a previous uninstall operation.  If so,
# enable the service now and re-export the manifest so that the persistent state
# reflects the live state.  We also remove the sentinel file: it's only intended
# for use across an upgrade.
#
if [[ -e /opt/smartdc/marlin/etc/enabled ]]; then
	svcadm enable -s marlin-agent
	svccfg export marlin-agent > $mpi_smfdir/marlin-agent.xml
	rm -f /opt/smartdc/marlin/etc/enabled
fi
