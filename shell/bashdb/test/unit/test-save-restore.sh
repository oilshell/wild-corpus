#!/bin/bash
# -*- shell-script -*-

# Test that we are saving and restoring POSIX variables IFS and PS4 that
# the debugger changes.
test_save_restore_IFS_PS4()
{
    typeset  _Dbg_space_IFS=' '
    typeset old_IFS="$IFS"
    typeset _Dbg_old_set_opts=$-
    typeset new_ifs=' 	'
    _Dbg_old_set_nullglob=1
    IFS="$new_ifs"
    PS4='123'
    _Dbg_set_debugger_entry
    assertEquals "$_Dbg_space_IFS" "$IFS"
    assertNotEquals '123' "$PS4"
    _Dbg_set_to_return_from_debugger 0
    assertNotEquals "$_Dbg_space_IFS" "$IFS"
    assertEquals "$new_ifs" "$IFS"
    IFS="$old_IFS"
}

abs_top_srcdir=/src/external-vcs/sourceforge/bashdb
# Make sure $abs_top_srcdir has a trailing slash
abs_top_srcdir=${abs_top_srcdir%%/}/
. ${abs_top_srcdir}test/unit/helper.sh
. ${abs_top_srcdir}/init/pre.sh
. ${abs_top_srcdir}/lib/journal.sh
. ${abs_top_srcdir}/lib/filecache.sh
. ${abs_top_srcdir}/lib/file.sh
. ${abs_top_srcdir}/lib/save-restore.sh
set -- # reset $# so shunit2 doesn't get confused.

[[ $0 == ${BASH_SOURCE} ]] && . ${shunit_file}
