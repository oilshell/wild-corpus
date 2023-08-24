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
# mrlogadmconf: configures logadm for the marlin agent.
# This operation is idempotent.
#

function fail
{
	echo "$*" >&2
	exit 1
}

tmpfile=/var/tmp/$(basename $0).$$

logadm -r marlin-agent
logadm -r mbackup
logadm -w "marlin-agent" -C 48 -c -p 1h \
    -t "/var/log/manta/upload/marlin-agent_\$nodename_%FT%H:00:00.log" \
    "/var/svc/log/*marlin-agent*.log" || fail "failed to add marlin-agent log"
logadm -w mbackup -C 3 -c -s 1m /var/log/mbackup.log || \
    fail "failed to add mbackup log"
grep -v smf_logs /etc/logadm.conf > $tmpfile
grep smf_logs /etc/logadm.conf >> $tmpfile
mv $tmpfile /etc/logadm.conf || fail "failed to update logadm.conf"
echo "updated logadm.conf"
