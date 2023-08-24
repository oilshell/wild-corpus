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
# Marlin agent preuninstall script: this is invoked before the Marlin package is
# uninstalled to disable and remove the SMF service.
#

set -o xtrace
set -o errexit

state=$(svcs -Hostate marlin-agent)

#
# To support upgrade properly, we save our current SMF state persistently.  When
# the upgraded package is installed, it can re-enable itself iff it was enabled
# before the uninstall.
#
if [[ "$state" == "online" || "$state" == "maintenance" ]]; then
	touch /opt/smartdc/marlin/etc/enabled
fi

svcadm disable -s marlin-agent
svccfg delete marlin-agent 
rm -f $npm_config_smfdir/marlin-agent.xml
