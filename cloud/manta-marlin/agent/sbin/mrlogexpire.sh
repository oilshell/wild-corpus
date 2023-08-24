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
# mrlogexpire.sh: invoked by cron to remove old per-stream debug logs
#

set -o pipefail
set -o errexit
set -o xtrace

echo "job expiration start: $(date)" >&2

mle_ndays=14
mle_logroot=/var/smartdc/marlin/log/zones

cd $mle_logroot
find . -mtime +$mle_ndays -exec rm -f "{}" \;

echo "job expiration done:  $(date)" >&2
