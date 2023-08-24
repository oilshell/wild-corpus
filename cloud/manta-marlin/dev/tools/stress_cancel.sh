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
# stress_cancel: runs a relatively large job continuously for a random number of
# seconds between [0, 15], cancels it, and waits for it to finish.
#

set -o errexit
set -o pipefail

lfile="/usr/dict/words"		# local file to use (contents not actually used)
rpath="/poseidon/stor/words"	# remote object path to use
mininputs=400			# minimum number of inputs
maxinputs=600			# maximum number of inputs
maxtimeout=15			# maximum time to wait before cancelling

jobid=
sleeptime=
nkeys=
njobs=0

function cleanup
{
	echo "completed \"$njobs\" iterations"
	[[ -n "$jobid" ]] || exit 1
	echo "$(date): abort: cancelling job $jobid"
	mjob cancel $jobid
	exit 1
}

echo "$(date): saving /usr/dict/words as /poseidon/stor/words"
mput -f $lfile $rpath

trap cleanup SIGINT

while :; do
	jobid=$(mjob create -n "stress_cancel" -m 'sleep 1' -r wc)
	[[ -n "$jobid" ]] || break
	echo "$(date): created job $jobid"

	nkeys=$(( RANDOM % (maxinputs - mininputs) + mininputs ))
	sleeptime=$(( RANDOM % maxtimeout ))
	echo "$(date): adding inputs and sleeping for $sleeptime seconds"
	yes /poseidon/stor/words | head -$nkeys | mjob addinputs $jobid &
	sleep $sleeptime
	wait

	echo "$(date): cancelling job"
	mjob cancel $jobid
	mjob watch $jobid
	echo "$(date): job done"
	sleep 3
	njobs=$(( njobs + 1 ))
done
