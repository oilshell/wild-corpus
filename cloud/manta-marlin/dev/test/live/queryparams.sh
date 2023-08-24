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
# queryparams.sh: script that tests that the Marlin lackey and agent proxy code
# properly passes through query parameters when proxying to Manta.
#
set -o errexit
set -o xtrace

function fail
{
	echo "$*" >&2
	exit 1
}

curl -Sfs 127.0.0.1/$MANTA_USER > /var/tmp/qparam1.out
count=$(wc -l < /var/tmp/qparam1.out)
[[ $count -gt 1 ]] || fail "need a directory with more than 1 object"

marker=$(tail -1 /var/tmp/qparam1.out | json name)
[[ -n "$marker" ]] || fail "marker not found"

curl -Sfs "127.0.0.1/$MANTA_USER?marker=$marker&limit=1024" \
    > /var/tmp/qparam2.out

diff /var/tmp/qparam1.out /var/tmp/qparam2.out && \
    fail "expected different results"
exit 0
