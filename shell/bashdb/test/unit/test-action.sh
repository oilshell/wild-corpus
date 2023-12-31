#!/bin/bash
# -*- shell-script -*-

# Test breakpoint set, unset, enable, disable, clear
test_action()
{
    # Some mock functions
    _Dbg_errmsg() {
	errmsgs+=("$@")
    }
    _Dbg_msg() {
	msgs+=("$@")
    }
    _Dbg_msg_nocr() {
	msgs+=("$@")
    }
    _Dbg_adjust_filename() {
	echo $*
    }
    _Dbg_expand_filename() {
	echo $*
    }

    _Dbg_readin "$shunit_file"

    typeset -a msgs
    msgs=()

    # Test parameter count checking for _Dbg_set_action
    _Dbg_set_action
    assertNotEquals '0' "$?"
    _Dbg_set_action 1 2 3 4 5
    assertNotEquals '0' "$?"

    _Dbg_set_action "$shunit_file" x=1 5
    assertNotEquals '0' "$?"

    assertEquals 0 $_Dbg_action_count

    # This should work
    _Dbg_set_action "$shunit_file" 5 x=1
    assertEquals "Action 1 set in file $shunit_file, line 5." "${msgs[0]}" 
    assertEquals 1 $_Dbg_action_count
    msgs=()

    # Test parameter count checking for _Dbg_unset_action
    _Dbg_unset_action
    assertNotEquals '0' "$?"
    _Dbg_unset_action 1 2 3
    assertNotEquals '0' "$?"

    _Dbg_unset_action "$shunit_file" foo
    assertNotEquals '0' "$?"

    # Shouldn't find this action
    _Dbg_unset_action "$shunit_file" 6
    rc=$?

    assertNotEquals '0' "$rc"
    assertEquals "No action found in file $shunit_file, line 6." "${errmsgs[0]}" 

    assertEquals 1 $_Dbg_action_count

    msgs=()
    # This should work and remove an action
    _Dbg_unset_action "$shunit_file" 5
    assertEquals '0' "$?"
    assertEquals '0' "${#msgs[@]}"
    assertEquals 0 $_Dbg_action_count

    # This should not work since action has already been removed.
    errmsgs=()
    _Dbg_unset_action "$shunit_file" 5
    assertNotEquals '0' "$?"
    assertEquals "No action found in file $shunit_file, line 5." "${errmsgs[0]}"

    msgs=(); errmsgs=()
    # Add another action for testing
    _Dbg_set_action $shunit_file 6 x=1
    assertEquals '0' "$?"
    assertEquals '1' "${#msgs[@]}"
    assertEquals "Action 2 set in file $shunit_file, line 6." "${msgs[0]}" 
    assertEquals 1 $_Dbg_action_count

    _Dbg_do_clear_action 1 2 3
    assertNotEquals '0' "$?"

    _Dbg_do_clear_action ${shunit_file} bogus
    assertNotEquals '0' "$?"

    msgs=(); errmsgs=()
    _Dbg_do_clear_action ${shunit_file}:6
    assertEquals 0 $_Dbg_action_count
    assertEquals '1' "${#msgs[@]}"
}

if [ '/src/external-vcs/sourceforge/bashdb' = '' ] ; then
  echo "Something is wrong abs_top_srcdir is not set."
 exit 1
fi

abs_top_srcdir=/src/external-vcs/sourceforge/bashdb
# Make sure /src/external-vcs/sourceforge/bashdb has a trailing slash
abs_top_srcdir=${abs_top_srcdir%%/}/
. ${abs_top_srcdir}test/unit/helper.sh
. ${abs_top_srcdir}init/pre.sh
. ${abs_top_srcdir}init/vars.sh
. ${abs_top_srcdir}lib/action.sh
. ${abs_top_srcdir}lib/file.sh
. ${abs_top_srcdir}lib/filecache.sh
. ${abs_top_srcdir}lib/fns.sh
. ${abs_top_srcdir}lib/journal.sh
. ${abs_top_srcdir}lib/validate.sh

. ${abs_top_srcdir}lib/alias.sh
. ${abs_top_srcdir}lib/help.sh
. ${abs_top_srcdir}command/action.sh
set -- # reset $# so shunit2 doesn't get confused.

[[ $0 == ${BASH_SOURCE} ]] && . ${shunit_file}
