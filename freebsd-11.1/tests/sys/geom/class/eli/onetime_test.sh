#!/bin/sh
# $FreeBSD: stable/11/tests/sys/geom/class/eli/onetime_test.sh 312829 2017-01-26 20:15:14Z asomers $

. $(dirname $0)/conf.sh

base=`basename $0`
sectors=100

echo "1..200"

do_test() {
	cipher=$1
	secsize=$2
	ealgo=${cipher%%:*}
	keylen=${cipher##*:}

	rnd=`mktemp $base.XXXXXX` || exit 1
	mdconfig -a -t malloc -s `expr $secsize \* $sectors`b -u $no || exit 1

	geli onetime -e $ealgo -l $keylen -s $secsize md${no} 2>/dev/null

	secs=`diskinfo /dev/md${no}.eli | awk '{print $4}'`

	dd if=/dev/random of=${rnd} bs=${secsize} count=${secs} >/dev/null 2>&1
	dd if=${rnd} of=/dev/md${no}.eli bs=${secsize} count=${secs} 2>/dev/null

	md_rnd=`dd if=${rnd} bs=${secsize} count=${secs} 2>/dev/null | md5`
	md_ddev=`dd if=/dev/md${no}.eli bs=${secsize} count=${secs} 2>/dev/null | md5`
	md_edev=`dd if=/dev/md${no} bs=${secsize} count=${secs} 2>/dev/null | md5`

	if [ ${md_rnd} = ${md_ddev} ]; then
		echo "ok $i - ealgo=${ealgo} keylen=${keylen} sec=${secsize}"
	else
		echo "not ok $i - ealgo=${ealgo} keylen=${keylen} sec=${secsize}"
	fi
	i=$((i+1))
	if [ ${md_rnd} != ${md_edev} ]; then
		echo "ok $i - ealgo=${ealgo} keylen=${keylen} sec=${secsize}"
	else
		echo "not ok $i - ealgo=${ealgo} keylen=${keylen} sec=${secsize}"
	fi
	i=$((i+1))

	geli detach md${no}
	rm -f $rnd
	mdconfig -d -u $no
}

i=1
for_each_geli_config_nointegrity do_test
