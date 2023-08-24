#!/bin/sh
#
# $FreeBSD: stable/11/contrib/ldns/freebsd-configure.sh 282088 2015-04-27 12:02:16Z des $
#

set -e

ldns=$(dirname $(realpath $0))
cd $ldns

libtoolize --copy
autoheader
autoconf
./configure --prefix= --exec-prefix=/usr

cd $ldns/drill
autoheader
autoconf
./configure --prefix= --exec-prefix=/usr
