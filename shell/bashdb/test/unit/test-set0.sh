#!/bin/bash
# -*- shell-script -*-

test_set0() {
    if ! enable -f ${abs_top_builddir}/builtin/set0 set0  >/dev/null 2>&1 ; then
	echo 'set0 tests skipped because you do not have the builtin'
	startSkipping
	return
    fi
    typeset oldname=$0
    set0 'newname' 'bar' 2>/dev/null
    assertFalse "set0 should fail." "$?"
    set0 'newname'
    assertTrue "set0 should work this time." "$?"
    assertEquals 'newname' "$0"
    [[ $oldname != $0 ]] 
    assertTrue "old $oldname should not equal new $0" "$?"
}

if [ '/src/external-vcs/sourceforge/bashdb' = '' ] ; then
  echo "Something is wrong: abs_top_srcdir is not set."
  exit 1
fi
abs_top_builddir=/src/external-vcs/sourceforge/bashdb
abs_top_builddir=${abs_top_builddir%%/}/
abs_top_srcdir=/src/external-vcs/sourceforge/bashdb
# Make sure $abs_top_srcdir has a trailing slash
abs_top_srcdir=${abs_top_srcdir%%/}/
. ${abs_top_srcdir}test/unit/helper.sh
set -- # reset $# so shunit2 doesn't get confused.

[[ $0 == ${BASH_SOURCE} ]] && . ${shunit_file}
