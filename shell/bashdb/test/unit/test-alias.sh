#!/bin/bash
# -*- shell-script -*-
test_alias()
{
    _Dbg_alias_add u up
    typeset expanded_alias=''; _Dbg_alias_expand u
    assertEquals 'up' $expanded_alias

    _Dbg_alias_add q quit
    expanded_alias=''; _Dbg_alias_expand q
    assertEquals 'quit' $expanded_alias

    typeset aliases_found=''
    _Dbg_alias_find_aliased quit
    assertEquals 'q' "$aliases_found"

    _Dbg_alias_add exit quit
    _Dbg_alias_find_aliased quit
    assertEquals 'exit, q' "$aliases_found"

    _Dbg_alias_remove q
    expanded_alias=''; _Dbg_alias_expand q
    assertEquals 'q' $expanded_alias

    _Dbg_alias_find_aliased quit
    assertEquals 'exit' "$aliases_found"

    expanded_alias=''; _Dbg_alias_expand u
    assertEquals 'up' $expanded_alias
}

if [ '/src/external-vcs/sourceforge/bashdb' = '' ] ; then
  echo "Something is wrong: abs_top_srcdir is not set."
 exit 1
fi
abs_top_srcdir=/src/external-vcs/sourceforge/bashdb
# Make sure $abs_top_srcr has a trailing slash
abs_top_srcdir=${abs_top_srcdir%%/}/
. ${abs_top_srcdir}test/unit/helper.sh
. $abs_top_srcdir/lib/help.sh
. $abs_top_srcdir/lib/alias.sh
set -- # reset $# so shunit2 doesn't get confused.
[[ $0 == ${BASH_SOURCE} ]] && . ${shunit_file}
