#!/bin/sh
#
# $FreeBSD: stable/11/crypto/openssh/freebsd-pre-merge.sh 294324 2016-01-19 14:25:22Z des $
#

:>keywords
:>rcsid
svn list -R | grep -v '/$' | \
while read f ; do
	svn proplist -v $f | grep -q 'FreeBSD=%H' || continue
	egrep -l '^(#|\.\\"|/\*)[[:space:]]+\$FreeBSD[:\$]' $f >>keywords
	egrep -l '__RCSID\("\$FreeBSD[:\$]' $f >>rcsid
done
sort -u keywords rcsid | xargs perl -n -i -e '
	$strip = $ARGV if /\$(Id|OpenBSD):.*\$/;
	print unless (($strip eq $ARGV || /__RCSID/) && /\$FreeBSD[:\$]/);
'
