#!/bin/bash
# -*- shell-script -*-

test_require()
{
    typeset -i require_me
    require_me=0
    require ./require_me.sh
    assertEquals  "Should have been required" 1 $require_me 
    typeset -i requires_size
    requires_size=${#_Dbg_requires[@]}
    require ./require_me.sh
    assertEquals  "Should not have required a second time" 1 $require_me
    assertEquals $requires_size ${#_Dbg_requires[@]}
    require require_me.sh
    assertEquals  "Should not have required under another name" 1 $require_me
    assertEquals $requires_size ${#_Dbg_requires[@]}
}

abs_top_srcdir=/src/external-vcs/sourceforge/bashdb
# Make sure $abs_top_srcdir has a trailing slash
abs_top_srcdir=${abs_top_srcdir%%/}/
. ${abs_top_srcdir}test/unit/helper.sh
. ${abs_top_srcdir}init/require.sh
set -- # reset $# so shunit2 doesn't get confused.

[[ $0 == ${BASH_SOURCE} ]] && . ${shunit_file}
