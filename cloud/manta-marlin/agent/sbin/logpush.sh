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
# logpush.sh: upload log files to Manta
#

set -o pipefail

# static configuration
lp_arg0=$(basename $0)
lp_dirtype='application/json; type=directory'
lp_logtype='application/json'
lp_lockfile=/tmp/$lp_arg0.lock
lp_ps4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${'
lp_ps4="${lp_ps4}FUNCNAME[0]}(): }"

# command-line options
lp_optf=false		# force run even if another instance is running
lp_optn=false		# dry-run mode
lp_optx=false		# use xtrace

# dynamic configuration initialized by configure()
MANTA_URL=		# full URL to Manta instance
MANTA_USER=		# manta username
MANTA_KEY_ID=		# manta key id
lp_logroot=		# local path with logs to upload
lp_manta_logroot=	# remote path to store logs
lp_authz_header=	# authorization HTTP header
lp_sshkey=		# path to ssh key
lp_nameserver=		# nameserver

lp_wrote_lockfile=false


# fail msg: prints "msg" to stderr and exits with failure
function fail
{
	echo "$lp_arg0: $*" >&2
	[[ lp_wrote_lockfile = "true" ]] && rm -f $lp_lockfile
	exit 1
}

# warn msg: prints "msg" to stderr and returns with failure
function warn
{
	echo "$lp_arg0: $*" >&2
	return 1
}

# usage: print usage message and exit
function usage
{
	[[ $# -gt 0 ]] && echo "$lp_arg0: $@" >&2
	cat >&2 <<-EOF
usage: $lp_arg0 [-fnx] configfile

Upload and then delete log files.

    -f    force run, even if another instance is already running
    -n    dry-run (do not actually upload files)
    -x    enable bash xtrace (for debugging)

Sample configuration:

    {
       "logroot": "/home/dap/logpush/sample_logs",
       "nameservers": [ "10.2.211.35" ]
       "manta": {
           "user": "poseidon",
           "host": "manta.bh1.joyent.us",
           "keypath": "/root/.ssh/id_rsa",
           "logroot": "/poseidon/stor/logs"
       }
    }
EOF
	exit 2
}

# manta uri [curl_args]: make a request to manta
function manta
{
	local now signature uri header

	now=$(date -u "+%a, %d %h %Y %H:%M:%S GMT") || fail "failed to get date"
	signature=$(echo "date: $now" | tr -d '\n' | \
            openssl dgst -sha256 -sign $lp_sshkey | \
	    openssl enc -e -a | tr -d '\n') || fail "failed to sign request"
	uri="$1"
	shift

	header="Authorization: Signature $lp_authz_header"
	header="$header,signature=\"$signature\""

	if [[ $lp_optn = "true" ]]; then
		echo "dry-run: curl ... $uri"
	else
		curl -fisSk \
		    -H "Date: $now"		\
		    -H "$header"		\
		    -H "Connection: close"	\
		    "$MANTA_URL$uri" "$@"
	fi
}

# manta_putfile uri content_type filepath: stream the given file to manta
function manta_putfile
{
	manta "$1" -X PUT -H "Content-Type: $2" -T "$3" || \
	    warn "manta put \"$1\" (from file $3) failed"
}

# manta_mkdir uri: create the given directory on Manta (idempotent)
function manta_mkdir
{
	manta "$1" -X PUT -H "Content-Type: $lp_dirtype" || \
	    warn "manta mkdir \"$1\" failed"
}

# manta_mkdirp uri: create the given directory tree on Manta (idempotent)
function manta_mkdirp
{
        local uri tl donesofar left first next

        uri="$1"
        tl=${uri#/*/stor}
        [[ -z "$tl" || "$uri" == "$tl" ]] &&
            fail "manta_mkdirp: invalid uri: $uri"

        donesofar=${uri%%$tl}
        while [[ "$donesofar" != "$uri" ]]; do
                left="${uri#$donesofar/}"
                donesofar="$donesofar/${left%%/*}"
		manta_mkdir "$donesofar" || return 1
        done
}

# configure configfile: load configuration from the given file
function configure
{
	json < $1 > /dev/null || fail "failed to read configuration from \"$1\""

	local host script

	MANTA_USER="$(json manta.user < $1)"
	host="$(json manta.host < $1)"
	lp_sshkey="$(json manta.keypath < $1)"
	lp_logroot="$(json logroot < $1)"
	lp_manta_logroot="$(json manta.logroot < $1)"

	script="this.x = this.nameservers[Math.floor("
	script="$script Math.random() * this.nameservers.length)]"
	lp_nameserver="$(json -e "$script" x < $1 2>/dev/null)"

	[[ -n "$MANTA_USER" ]] || fail "config error: manta.user not present"
	[[ -n "$host" ]] || fail "config error: manta.host not present"
	[[ -n "$lp_sshkey" ]] || fail "config error: manta.keypath not present"
	[[ -n "$lp_logroot" ]] || fail "config error: logroot not present"
	[[ -n "$lp_manta_logroot" ]] || \
	    fail "config error: manta.logroot not present"

	if [[ -n "$lp_nameserver" ]]; then
		#
		# Newer versions of dig(1) sometimes emit warnings to stdout,
		# even with +short and even when the query is otherwise
		# successful.  Ignore those here.  They start with ";;".
		#
		echo "will use nameserver $lp_nameserver to resolve $host"
		host=$(dig $host @$lp_nameserver +short | \
		    grep -v '^;;' | head -1)
		[[ -n "$host" ]] || \
		    fail "failed to resolve $host from $lp_nameserver"
	fi

	MANTA_URL="http://$host"
	MANTA_KEY_ID=$(ssh-keygen -l -f $lp_sshkey.pub | awk '{print $2}') || \
	    fail "failed to extract key id from \"$lp_sshkey.pub\""
	lp_authz_header="keyId=\"/$MANTA_USER/keys/$MANTA_KEY_ID\""
	lp_authz_header="$lp_authz_header,algorithm=\"rsa-sha256\""

	cat <<EOF
Configuration:
    MANTA_USER:     $MANTA_USER
    MANTA_URL:      $MANTA_URL
    MANTA_KEY_ID:   $MANTA_KEY_ID
    Manta log root: $lp_manta_logroot
    Local log root: $lp_logroot
    ssh key:        $lp_sshkey
EOF
}

#
# logpush_all: find and push all log files (based on configuration)
#
function logpush_all
{
	for file in $lp_logroot/*; do
		[[ ! -f "$file" ]] && continue
		logpush $file
	done

	echo "Processed all files."
}

#
# logpush logfile: push the given log file to Manta
# The filename should have the form "service_zonename_timestamp[.suffix]", as in
#
#     config-agent_2dc68d18-fb5c-4eda-aba7-69aae57b3ec4_2013-05-06T18:00:00.log
#
# It will be uploaded to
#
#     .../config-agent/2013/05/06/18/2dc68d18.log
#
function logpush
{
	local p service zone logtime script uritime uri

	# Extract the underscore-delimeted components in order.
	p="$(basename $1)"
	service="${p%%_*}"
	p="${p#${service}_}"

	zone="${p%%_*}"
	p="${p#${zone}_}"
	zone="${zone%%-*}"

	# Remove the optional trailing suffix.
	logtime="${p%.*}"

	#
	# Some versions of the date(1) command are capable of translating
	# between different datetime formats, but they all use different flags
	# to do so, and the only one we have available here (/usr/bin/date)
	# doesn't support it at all.
	#
	# We could nearly just parse the pieces out using cut(1), except that
	# the timestamp in the filename is actually one hour *after* the desired
	# timestamp.  Since we need to actually parse the date properly, we use
	# a little node program.
	#
	script="s = new Date(Date.parse('$logtime') - 3600 * 1000)"
	script="$script; y = s.getUTCFullYear()"
	script="$script; m = s.getUTCMonth() + 1"
	script="$script; d = s.getUTCDate()"
	script="$script; h = s.getUTCHours()"
	script="$script; if (m < 10) m = '0' + m"
	script="$script; if (d < 10) d = '0' + d"
	script="$script; if (h < 10) h = '0' + h"
	script="$script; console.log('%s/%s/%s/%s', y, m, d, h);"
	uritime=$(/usr/node/bin/node -e "$script") || \
	    fail "failed to parse log time"
	uri="$lp_manta_logroot/$service/$uritime/$zone.log"

	if ! manta_mkdirp "$(dirname "$uri")" ||
	    ! manta_putfile "$uri" "$lp_logtype" "$1"; then
		warn "failed to push \"$1\""
		return 1
	fi

	[[ $lp_optn == "false" ]] && rm -f "$1"
}

#
# check_running: check whether another instance of this script is already
# running and bail out if so.
#
function check_running
{
	echo $$ > $lp_lockfile.tmp

	if ln $lp_lockfile.tmp $lp_lockfile > /dev/null 2>&1; then
		rm -f $lp_lockfile.tmp
		return 0
	fi

	if kill -0 "$(cat $lp_lockfile)" >/dev/null 2>&1; then
		[[ $lp_optf != "true" ]] && \
		    fail "process $(cat $lp_lockfile) is still running"
		warn "process $(cat $lp_lockfile) is still running, but" \
		    "removing its lockfile because -f was specified"
	else
		warn "cleaning up leftover $lp_lockfile"
	fi

	rm -f $lp_lockfile || fail "failed to remove $lp_lockfile"
	check_running
	lp_wrote_lockfile=true
}


#
# Mainline
#
while getopts ":fhnx" c "$@"; do
	case "$c" in
	f|n|x)	eval lp_opt$c=true ;;
	h)	usage ;;
	:)	usage "option requires an argument -- $OPTARG" ;;
	*)	usage "invalid option: $OPTARG" ;;
	esac
	
done

if [[ $lp_optx == "true" ]]; then
	export PS4="$lp_ps4"
	set -o xtrace
fi

shift -- $((OPTIND-1))
[[ $# -eq 0 ]] && usage
check_running
configure "$1"
logpush_all
rm -f $lp_lockfile
