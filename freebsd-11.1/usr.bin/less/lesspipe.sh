#! /bin/sh
# ex:ts=8

# $FreeBSD: stable/11/usr.bin/less/lesspipe.sh 294111 2016-01-15 23:13:01Z ak $

case "$1" in
	*.zip)
		exec unzip -c "$1" 2>/dev/null
		;;
	*.Z)
		exec uncompress -c "$1"	2>/dev/null
		;;
	*.gz)
		exec gzip -d -c "$1"	2>/dev/null
		;;
	*.bz2)
		exec bzip2 -d -c "$1"	2>/dev/null
		;;
	*.xz)
		exec xz -d -c "$1"	2>/dev/null
		;;
	*.lzma)
		exec lzma -d -c "$1"	2>/dev/null
		;;
esac
