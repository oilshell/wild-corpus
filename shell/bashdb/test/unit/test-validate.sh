#!/bin/bash
# -*- shell-script -*-
test_validate_is_function()
{
    _Dbg_is_function 
    assertFalse 'No function given; is_function should report false' $? 

    unset -f function_test
    _Dbg_is_function function_test
    assertFalse 'function_test should not be defined' "$?"

    typeset -i function_test=1
    _Dbg_is_function function_test
    assertFalse 'test_function should still not be defined' "$?"

    function_test() { :; }
    _Dbg_is_function function_test
    assertTrue 'test_function should now be defined' "$?"

    function another_function_test { :; }
    _Dbg_is_function another_function_test "$?"

    _function_test() { :; }
    _Dbg_is_function _function_test
    assertFalse 'fn _function_test is system fn; is_function should report false' $? 

    _Dbg_is_function _function_test 1 
    assertTrue 'fn _function_test is system fn which we want; should report true' $? 

}

# Test _Dbg_is_int
test_validate_is_integer()
{
    _Dbg_is_int
    assertFalse 'No integer given; is_int should report false' $? 

    for arg in a a1 '-+-' ; do
	_Dbg_is_int $arg
	assertFalse "$arg is not an integer; is_int should report false" $? 
    done

    for arg in 0 123 9999999 ; do
	_Dbg_is_int $arg
	assertTrue "$arg is an integer; is_int should report true" $? 
	_Dbg_is_signed_int $arg
	assertTrue "$arg is a signed integer; is_int should report true" $? 
    done

    for arg in +0 -123 ; do
	_Dbg_is_signed_int $arg
	assertTrue "$arg is not a signed integer; is_int should report true" $? 
	_Dbg_is_int $arg
	assertFalse "$arg is not an integer; is_int should report true" $? 
    done

}

# Make sure /src/external-vcs/sourceforge/bashdb has a trailing slash
if [ '/src/external-vcs/sourceforge/bashdb' = '' ] ; then
  echo "Something is wrong: abs_top_srcdir is not set."
 exit 1
fi
abs_top_srcdir=/src/external-vcs/sourceforge/bashdb
# Make sure $abs_top_srcr has a trailing slash
abs_top_srcdir=${abs_top_srcdir%%/}/
. ${abs_top_srcdir}test/unit/helper.sh
. ${abs_top_srcdir}init/vars.sh
. ${abs_top_srcdir}init/pre.sh
. ${abs_top_srcdir}lib/journal.sh
. ${abs_top_srcdir}lib/save-restore.sh
. ${abs_top_srcdir}lib/validate.sh
set -- # reset $# so shunit2 doesn't get confused.

[[ $0 == ${BASH_SOURCE} ]] && . ${shunit_file}
