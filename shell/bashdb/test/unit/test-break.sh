#!/bin/bash
# -*- shell-script -*-
# Test breakpoint set, unset, enable, disable, clear
test_breakpoint() {
    # Some mock functions
    _Dbg_errmsg() {
	errmsgs+=("$@")
    }
    _Dbg_msg() {
	msgs+=("$@")
    }
    _Dbg_adjust_filename() {
	echo $*
    }
    _Dbg_expand_filename() {
	echo $*
    }

    typeset -a msgs
    msgs=()

    # Test parameter count checking for _Dbg_set_brkpt
    _Dbg_set_brkpt 
    assertNotEquals 'set breakpoint no parameters' '0' "$?"
    _Dbg_set_brkpt 1 2 3 4 5
    assertNotEquals 'set breakpoint too many parameter' '0' "$?"

    # This should work
    _Dbg_frame_last_lineno=5
    _Dbg_set_brkpt test.sh 5 0
    assertEquals 'simple set breakpoint' \
	'Breakpoint 1 set in file test.sh, line 5.' "${msgs[0]}" 
    msgs=()

    # Test parameter count checking for _Dbg_unset_brkpt
    _Dbg_unset_brkpt
    assertEquals 'unset_brkpt no params invalid' '0' "$?"
    _Dbg_unset_brkpt 1 2 3
    assertEquals '0' "$?"
# FIXME
#     # Shouldn't find this breakpoint
#     _Dbg_unset_brkpt test.sh 6
#     assertEquals '0' "$?"
#     assertEquals 'No breakpoint found at test.sh:6' "${msgs[0]}" 

    msgs=()
    # This should work and remove a breakpoint
    _Dbg_unset_brkpt test.sh 5
    assertEquals 'valid unset_brkpt' '1' "$?"
    assertEquals '0' "${#msgs[@]}"

# FIXME
#     # This should not work since breakpoint has already been removed.
#     _Dbg_unset_brkpt test.sh 5
#     assertEquals '0' "$?"
#     assertEquals 'No breakpoint found at test.sh:5' "${msgs[0]}"

    msgs=(); errmsgs=()
    # Enable/disable parameter checking
    _Dbg_enable_disable_brkpt
    assertEquals 'enable_disable_brkpt' '1' "$?"

    # Enable a non-existent breakpoint
    msgs=()
    _Dbg_enable_disable_brkpt 1 'enabled' 1
    assertEquals "enable_disable_brkpt enabled" \
	"Breakpoint entry 1 doesn't exist, so nothing done." "${errmsgs[0]}" 

    msgs=(); errmsgs=()
    # Add another breakpoint for testing
    _Dbg_set_brkpt test.sh 6 1
    assertEquals 'add 2nd breakpoint' \
	'One-time breakpoint 2 set in file test.sh, line 6.' "${msgs[0]}" 

    msgs=(); errmsgs=()
    _Dbg_enable_disable_brkpt 1 'enabled' 2
    assertEquals 'redundant 2nd breakpoint enable' \
	'Breakpoint entry 2 already enabled, so nothing done.' "${errmsgs[0]}" 

    msgs=(); errmsgs=()
    _Dbg_enable_disable_brkpt 0 'enabled' 2
    assertEquals 'Breakpoint entry 2 enabled.' "${msgs[0]}" 

    msgs=(); errmsgs=()
    _Dbg_enable_disable_brkpt 1 'disabled' 2
    assertEquals '0' "$?"
    assertEquals 'Breakpoint entry 2 disabled.' "${msgs[0]}" 

    _Dbg_clear_all_brkpt
}

abs_top_srcdir=/src/external-vcs/sourceforge/bashdb
# Make sure @abs_top_srcrdir@ has a trailing slash
abs_top_srcdir=${abs_top_srcdir%%/}/
. ${abs_top_srcdir}test/unit/helper.sh
. $abs_top_srcdir/init/pre.sh
. $abs_top_srcdir/lib/file.sh
. $abs_top_srcdir/lib/fns.sh
. $abs_top_srcdir/lib/journal.sh
. $abs_top_srcdir/lib/break.sh
. $abs_top_srcdir/lib/validate.sh
set -- # reset $# so shunit2 doesn't get confused.
[[ $0 == ${BASH_SOURCE} ]] && . ${shunit_file}
