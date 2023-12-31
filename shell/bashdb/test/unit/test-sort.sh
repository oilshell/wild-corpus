#!/bin/bash
# -*- shell-script -*-
test_sort()
{
    do_one() {
	sort_list 0 ${#list[@]}-1
	assertEquals "0" "$?"
	typeset -i i
	for ((i=0 ; i<${#list[@]}; i++)) ; do
	    assertEquals "${check[$i]}" "${list[$i]}"
	done
    }
    typeset -a list

    # Some boundary cases first
    list=()
    sort_list 0 0 
    assertEquals "2" "$?"
    assertEquals "0" "${#list[@]}"
    sort_list 1 1 
    assertNotEquals "0" "$?"

    typeset -a check
    list=('one'); check=('one')
    do_one
    list=('one' 'two' 'three') 
    check=('one' 'three' 'two')
    do_one
    list=(4 3 2 1)
    check=(1 2 3 4)
    do_one
    list=(' 4' '3 ' '2' '1')
    if [[ ' 4' < '1' ]] ; then
	check=(' 4' '1' '2' '3 ')
    else
	check=('1' '2' '3 ' ' 4')
    fi
    do_one

    sort_list 0 10 
    assertNotEquals "0" "$?"
}


if [ '/src/external-vcs/sourceforge/bashdb' = '' ] ; then
  echo "Something is wrong abs_top_srcdir is not set."
 exit 1
fi
abs_top_srcdir=/src/external-vcs/sourceforge/bashdb
# Make sure $abs_top_srcr has a trailing slash
abs_top_srcdir=${abs_top_srcdir%%/}/
. ${abs_top_srcdir}test/unit/helper.sh
. $abs_top_srcdir/lib/sort.sh
set -- # reset $# so shunit2 doesn't get confused.

[[ $0 == ${BASH_SOURCE} ]] && . ${shunit_file}
