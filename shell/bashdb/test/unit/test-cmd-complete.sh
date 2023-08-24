#!/bin/bash
# -*- shell-script -*-
# Test command completion
test_cmd_complete()
{
    output=$(_Dbg_do_complete c)
    assertEquals 'condition
continue
complete
commands
clear' "$output"
}

if [ '/src/external-vcs/sourceforge/bashdb' = '' ] ; then
  echo "Something is wrong; 'abs_top_srcdir' is not set."
 exit 1
fi
abs_top_srcdir=/src/external-vcs/sourceforge/bashdb
# Make sure $abs_top_srcrdir has a trailing slash
abs_top_srcdir=${abs_top_srcdir%%/}/
. ${abs_top_srcdir}test/unit/helper.sh
. ${abs_top_srcdir}init/require.sh
. ${abs_top_srcdir}lib/help.sh
. ${abs_top_srcdir}lib/alias.sh
. ${abs_top_srcdir}lib/complete.sh

for _Dbg_file in ${abs_top_srcdir}command/c*.sh ; do 
    source $_Dbg_file
done

set -- # reset $# so shunit2 doesn't get confused.
[[ $0 == ${BASH_SOURCE} ]] && . ${shunit_file}
