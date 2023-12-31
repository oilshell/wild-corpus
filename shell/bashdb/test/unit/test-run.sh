#!/bin/bash
# -*- shell-script -*-

test_run_not_running()
{
    typeset -a errs=()
    _Dbg_errmsg() { errs+=$1; }
    typeset -i _Dbg_running=1
    _Dbg_running=1
    _Dbg_not_running
    assertFalse 'Should report running.' "$?"
    assertEquals  0 ${#errs[@]}
    _Dbg_running=0
    _Dbg_not_running
    assertTrue 'Should report not running.' "$?"
    assertEquals  1 ${#errs[@]}
}

abs_top_srcdir=/src/external-vcs/sourceforge/bashdb
# Make sure $abs_top_srcdir has a trailing slash
abs_top_srcdir=${abs_top_srcdir%%/}/
. ${abs_top_srcdir}test/unit/helper.sh
. ${abs_top_srcdir}/lib/run.sh
set -- # reset $# so shunit2 doesn't get confused.

[[ $0 == ${BASH_SOURCE} ]] && . ${shunit_file}
