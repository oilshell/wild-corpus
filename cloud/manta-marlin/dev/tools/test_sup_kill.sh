#!/bin/bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright (c) 2014, Joyent, Inc.
#

if [[ -z "$1" ]]; then
	echo "usage: $0 [PGREP_ARGS]" >&2
	echo "Try using '-P PPID', where PPID is the shell you launched " >&2
	echo "the jobsupervisor from." >&2
	exit 2
fi

#
# test_sup_kill.sh: periodically kills the jobsupervisor (used for stress
# testing).
#
while sleep $(( RANDOM % 30 + 5 )); do
	date
	pkill "$@"
done
