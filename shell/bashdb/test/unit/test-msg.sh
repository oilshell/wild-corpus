#!/bin/bash
# -*- shell-script -*-

test_msg()
{
    local -i _Dbg_logging=0
    local -i _Dbg_logging_redirect=0
    local _Dbg_tty=''
    local msg=$(_Dbg_msg hi)
    assertEquals 'hi' "$msg"
    msg=$(_Dbg_msg_nocr hi)
    assertEquals 'hi' "$msg"
    msg=$(_Dbg_printf '%03d' 5)
    assertEquals '005' "$msg"
    msg=$(_Dbg_printf_nocr '%-3s' 'fo')
    assertEquals 'fo ' "$msg"
}

test_undefined()
{
    typeset -i _Dbg_logging=0
    typeset -i _Dbg_logging_redirect=0
    typeset _Dbg_tty=''
    typeset msg
    msg=$(_Dbg_undefined_cmd foo bar)
    assertEquals '** Undefined foo subcommand "bar". Try "help foo".' "$msg"
    msg=$(_Dbg_undefined_cmd foo)
    assertEquals '** Undefined command "foo". Try "help".' "$msg"
}

abs_top_srcdir=/src/external-vcs/sourceforge/bashdb
# Make sure $abs_top_srcdir has a trailing slash
abs_top_srcdir=${abs_top_srcdir%%/}/
. ${abs_top_srcdir}test/unit/helper.sh
. ${abs_top_srcdir}/lib/msg.sh
. ${abs_top_srcdir}/init/io.sh
_Dbg_set_highlight=''
set -- # reset $# so shunit2 doesn't get confused.

[[ $0 == ${BASH_SOURCE} ]] && . ${shunit_file}
