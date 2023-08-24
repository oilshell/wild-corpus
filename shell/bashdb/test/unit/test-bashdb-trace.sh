#!/bin/bash
# -*- shell-script -*-
test_preserve_set_opts()
{
    set -u
    old_opts=$-
    _Dbg_dbg_opts_test=''
    # If running make distcheck we can't use top_builddir
    # because some files aren't there but are in the install
    # directory. 
    if [[ -f $top_builddir/init/opts.sh ]] ; then
	libdir=${top_builddir}
    else
	libdir=${prefix}/share/bashdb
    fi
    if [[ -f $libdir/init/opts.sh ]] ; then
	# Name we refer to ourselves by
	typeset _Dbg_debugger_name='bashdb'
	# The release name we are configured to run under.
	typeset _Dbg_release='4.4-0.92'
	. ${top_builddir}/bashdb-trace -L $libdir
	assertEquals $old_opts $-
    else
	echo 'Skipping test - building outside of source complications'
    fi

    (. ${top_builddir}/bashdb-trace -L $libdir/init/opts.sh)
    assertEquals $? 1
    set +u
}

prefix=/usr/share
top_builddir=/src/external-vcs/sourceforge/bashdb
abs_top_srcdir=/src/external-vcs/sourceforge/bashdb
# Make sure $abs_top_srcrdir has a trailing slash
abs_top_srcdir=${abs_top_srcdir%%/}/
. ${abs_top_srcdir}test/unit/helper.sh
. ${abs_top_srcdir}/lib/filecache.sh
. ${abs_top_srcdir}/lib/sig.sh
. ${abs_top_srcdir}/lib/help.sh
. ${abs_top_srcdir}/command/trace.sh
set -- # reset $# so shunit2 doesn't get confused.

[[ $0 == ${BASH_SOURCE} ]] && . ${shunit_file}
