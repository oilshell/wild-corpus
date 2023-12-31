#!/bin/bash
# -*- shell-script -*-
this_script=test-get-sourceline.sh

abs_top_srcdir=/src/external-vcs/sourceforge/bashdb
# Make sure $abs_top_srcdir has a trailing slash
abs_top_srcdir=${abs_top_srcdir%%/}/

# Test _Dbg_get_source_line
test_get_source_line()
{
    _Dbg_get_source_line 2 $this_script
    assertEquals '# -*- shell-script -*-' "$_Dbg_source_line"
}

# Test check_line
# test should appear after tests which read in source.
test_get_source_line_with_spaces()
{
    _Dbg_frame_last_filename="${abs_top_srcdir}test/example/dir with spaces/bug.sh"
    # Can't figure out how to get this packaged with autoconf, so this
    # will work with git only.
    _Dbg_frame_file
    if [[ -f $_Dbg_frame_filename ]] && [[ $_Dbg_frame_filename =~ 'frame.sh' ]] ; then
	_Dbg_get_source_line 2
	assertEquals 'x=1' "$_Dbg_source_line"
    else
	startSkipping
	echo "Skipping test due to autoconf problems"
	assertEquals 'skipped' 'skipped'
	endSkipping
    fi
}

if [ '/src/external-vcs/sourceforge/bashdb' = '' ] ; then
  echo "Something is wrong abs_top_srcdir is not set."
 exit 1
fi

. ${abs_top_srcdir}test/unit/helper.sh
. ${abs_top_srcdir}init/pre.sh
. ${abs_top_srcdir}lib/filecache.sh
. ${abs_top_srcdir}lib/file.sh
. ${abs_top_srcdir}lib/frame.sh
. ${abs_top_srcdir}lib/msg.sh
_Dbg_set_highlight=''
set -- # reset $# so shunit2 doesn't get confused.

[[ $0 == ${BASH_SOURCE} ]] && . ${shunit_file}
