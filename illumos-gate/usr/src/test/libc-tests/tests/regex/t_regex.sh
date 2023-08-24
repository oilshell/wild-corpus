#! /usr/bin/sh
#
#
# This file and its contents are supplied under the terms of the
# Common Development and Distribution License ("CDDL"), version 1.0.
# You may only use this file in accordance with the terms of version
# 1.0 of the CDDL.
#
# A full copy of the text of the CDDL should have accompanied this
# source.  A copy of the CDDL is also available via the Internet at
# http://www.illumos.org/license/CDDL.
#

#
# Copyright 2017 Nexenta Systems, Inc.
#

TESTDIR=$(dirname $0)
HREGEX=${TESTDIR}/h_regex

for t in $TESTDIR/data/*.in; do
	$HREGEX < $t || exit 1
	$HREGEX -el < $t || exit 1
	$HREGEX -er < $t || exit 1
done
