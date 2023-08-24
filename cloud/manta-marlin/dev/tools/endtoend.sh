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
# endtoend.sh: run 100 inputs through a job and show the time taken for each
# one's output to be committed.
#

function fail
{
	echo "$(basename $0): $@"
	exit 1
}

ee_count=100
ee_mdir="/$MANTA_USER/stor/dbg-endtoend"
ee_jobid=
ee_inputs=
ee_tmpdir="/var/tmp/$(basename $0).$$"

mmkdir -p "$ee_mdir"

for (( i = 0; i < ee_count; i++ )) {
	head /usr/dict/words | mput "$ee_mdir/$i" || fail "failed to create $i"
	ee_inputs="$ee_inputs $ee_mdir/$i"
}

ee_jobid=$(mjob create -m wc) || fail "failed to create job"
echo "job $ee_jobid"
for inp in $ee_inputs; do
	echo $inp | mjob addinputs --open $ee_jobid || \
	    fail "failed to add input \"$inp\""
done
mjob close $ee_jobid || fail "failed to close job"
mjob watch $ee_jobid || fail "failed to watch job"

mkdir "$ee_tmpdir"
findobjects marlin_taskoutputs_v2 jobId=$ee_jobid | \
    json -ga value.input value.timeCommitted | sort > "$ee_tmpdir/outputs"
findobjects marlin_jobinputs_v2 jobId=$ee_jobid | \
    json -ga value.input value.timeCreated | sort > "$ee_tmpdir/inputs"
join "$ee_tmpdir"/{inputs,outputs} > "$ee_tmpdir/joined"
cat > "$ee_tmpdir"/sum.js <<EOF
var l = '';
process.stdin.on('data', function (c) { l += c.toString('utf8'); });
process.stdin.on('end', function () {
	var lines = l.split(/\n/);
	lines.forEach(function (line, i) {
		if (line.trim().length === 0)
			return;

		var parts = line.split(/\s+/);
		if (parts.length !== 3) {
			console.error('line garbled: %d', i);
			return;
		}

		console.log('%s %d', parts[0],
		    Date.parse(parts[2]) - Date.parse(parts[1]));
	});
});
EOF
node $ee_tmpdir/sum.js < "$ee_tmpdir/joined" | tee "$ee_tmpdir/summary"
