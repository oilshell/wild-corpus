#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright (c) 2014, Joyent, Inc.
#

#
# util.sh: common marlin script utility functions
#

m_agenturl="${AGENT_URL:-http://localhost:9080}"

set -o pipefail

function fail
{
	echo "$arg0: $*" >&2
	exit 1
}

function curlagent
{
	local url="$m_agenturl"
	local path=$1
	local tmpfile=/var/tmp/$arg0.$$
	local status
	shift

	if ! curl -is "$@" "$url$path" > $tmpfile; then
		echo "$arg0: failed to hit \"$url\" (see $tmpfile)" >&2
		return 1
	fi

	status="$(grep '^HTTP' $tmpfile | head -1 | awk '{print $2}')"
	if [[ $status -ge 400 ]]; then
		echo "$arg0: \"$url\" failed (code $status see $tmpfile)" >&2
		return 1
	fi

	nawk '/^\r$/,EOF' $tmpfile
	rm -f $tmpfile
}

function zone_disable
{
	local zonename=$1

	if ! curlagent /zones/$zonename/disable -XPOST > /dev/null; then
		echo "$mr_arg0: failed to disable zone \"$zonename\"" >&2
		return 1
	fi
}

