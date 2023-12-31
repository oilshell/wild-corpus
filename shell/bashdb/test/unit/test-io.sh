#!/bin/bash
# -*- shell-script -*-

test_progress_show()
{
    local -i _Dbg_logging=0
    local -i _Dbg_logging_redirect=0
    local _Dbg_tty=''
    local EMACS=t
    local bar=$(_Dbg_progess_show foo 10 3)
    assertEquals 'foo: [============> ' "${bar:3:20}"
}

# load shunit2
abs_top_srcdir=/src/external-vcs/sourceforge/bashdb
# Make sure $abs_top_srcdir has a trailing slash
abs_top_srcdir=${abs_top_srcdir%%/}/
. ${abs_top_srcdir}test/unit/helper.sh
. ${abs_top_srcdir}/lib/msg.sh
. ${abs_top_srcdir}/init/io.sh
set -- # reset $# so shunit2 doesn't get confused.

[[ $0 == ${BASH_SOURCE} ]] && . ${shunit_file}
