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
# delete_test_users.sh: remove UFDS users, ssh keys, roles, and policies created
# by the Marlin test suite.
#

#
# fail MESSAGE ...: print MESSAGE to stderr and exit with a failure code.
#
function fail
{
	echo "$(basename $0): $@" >&2
	exit 1
}

#
# wipe_account ACCOUNT: Wipe a top-level UFDS account (identified by account
# login) by manually removing each role, policy, and subuser and then removing
# the top-level user itself (which will remove its keys).
#
function wipe_account
{
	local account basedn

	account="$1"
	echo "wiping account \"$account\" ... " >&2

	basedn="$(sdc-ldap search login="$account" | \
	    awk -F: '$1 == "dn"{ print $2 }')"
	if [[ -z "$basedn" ]]; then
		echo "    note: account \"$account\" does not exist." >&2
		return 0
	fi

	list_children "$basedn" "objectclass=sdcaccountrole" | \
	    while read basedn; do
	    	delete_object "$basedn"
	    done

	list_children "$basedn" "objectclass=sdcaccountpolicy" | \
	    while read basedn; do
	    	delete_object "$basedn"
	    done

	list_children "$basedn" "objectclass=sdcaccountuser" | \
	    while read basedn; do
		wipe_user "$basedn"
	    done

	wipe_user "$basedn"
}

#
# list_children BASEDN FILTER: list the LDAP child entries of BASEDN that match
# FILTER.  Emits one line per result with the DN of the matching child entry.
#
function list_children
{
	local basedn filter

	basedn="$1"
	filter="$2"

	sdc-ldap search -b "$basedn" "$filter" | \
	    awk '/^dn:/{ $1 = ""; print $0 }'
}

#
# wipe_user BASEDN: wipes a UFDS user, which may be either a top-level user or a
# subuser.  This removes the keys and then the user itself.
#
function wipe_user
{
	local basedn

	basedn="$1"

	list_children "$basedn" "objectclass=sdckey" | \
	    while read basedn; do
		delete_object "$basedn"
	    done

	delete_object "$basedn"
}

#
# delete_object BASEDN: wipes a single entry from UFDS, which must have no
# children by this point.
#
function delete_object
{
	if [[ $mt_force == "true" ]]; then
		echo "    delete: $1"
		sdc-ldap delete "$1"
	else
		echo "    found:  $1"
	fi
}

#
# Configuration
#

# List of accounts to wipe
mt_accounts="marlin_test marlin_test_user_xacct marlin_test_authzA"
mt_accounts="$mt_accounts marlin_test_authzB"

# Only remove entries if mt_force == true.
mt_force="false"

# Parse arguments.
if [[ "$1" == "-f" ]]; then
	mt_force="true"
fi

#
# Since it's easy to run this in a context where it won't work (e.g., a dev zone
# without sdc-ldap installed), do a quick check now to make sure that sdc-ldap
# is available.
#
which sdc-ldap > /dev/null 2>&1 || \
    fail "sdc-ldap not found (try running in global zone?)"

for account in $mt_accounts; do
	wipe_account "$account"
done

if [[ "$mt_force" = "false" ]]; then
	echo "$(basename $0): use -f to remove entries." >&2
fi
