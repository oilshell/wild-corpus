#!/bin/sh
#
# $FreeBSD: stable/11/crypto/openssh/freebsd-post-merge.sh 294320 2016-01-19 12:38:53Z des $
#

xargs perl -n -i -e '
	print;
	s/\$(Id|OpenBSD): [^\$]*/\$FreeBSD/ && print;
' <keywords

xargs perl -n -i -e '
	print;
	m/^\#include "includes.h"/ && print "__RCSID(\"\$FreeBSD\$\");\n";
' <rcsid
