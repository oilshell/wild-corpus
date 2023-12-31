#!/bin/bash
# -*- shell-script -*-

test_parse_list_args()
{
    # Set up necessary vars
    _Dbg_frame_last_filename='testing'
    typeset -i _Dbg_frame_last_lineno
    typeset -i _Dbg_set_listsize
    _Dbg_set_listsize=12
    typeset -i _Dbg_frame_last_lineno
    _Dbg_frame_last_lineno=3

    # Return vars
    typeset filename
    typeset end_line

    # Some error conditions
    _Dbg_parse_list_args 
    assertEquals 1 $?
    _Dbg_parse_list_args "foo"
    assertEquals 1 $?
    

    # Try a simple parse
    _Dbg_parse_list_args 0 100 "$_Dbg_frame_last_filename" 
    assertEquals "$_Dbg_frame_last_filename" "$filename"
    assertEquals 1 "$_Dbg_listline"
    assertEquals 12 "$end_line"

    # Try with a line number
    _Dbg_parse_list_args 0 100 "$_Dbg_frame_last_filename" 15
    assertEquals "$_Dbg_frame_last_filename" "$filename"
    assertEquals 9 "$_Dbg_listline"
    assertEquals $((9+_Dbg_set_listsize-1)) "$end_line"

    # Try with a line number and count
    _Dbg_parse_list_args 0 100 "$_Dbg_frame_last_filename" 20 3
    assertEquals "$_Dbg_frame_last_filename" "$filename"
    assertEquals 19 "$_Dbg_listline"
    assertEquals $((19+3-1)) "$end_line"

    # Try with start and end line number 
    _Dbg_parse_list_args 0 100 "$_Dbg_frame_last_filename" 10+20 35
    assertEquals "$_Dbg_frame_last_filename" "$filename"
    assertEquals 30 "$_Dbg_listline"
    assertEquals 35 "$end_line"

    # Try with . and end line number 
    _Dbg_parse_list_args 0 100 "$_Dbg_frame_last_filename" '.' 
    assertEquals 1 "$_Dbg_listline"
    assertEquals 12 "$end_line" 

    # Try with line numbers from the end
    _Dbg_parse_list_args 0 100 "$_Dbg_frame_last_filename" -5 
    assertEquals 90 "$_Dbg_listline"

    _Dbg_parse_list_args 0 100 "$_Dbg_frame_last_filename" 5 -5 
    assertEquals 96 "$end_line"

    # Try with centered line numbers
    _Dbg_parse_list_args 1 100 "$_Dbg_frame_last_filename" 10
    assertEquals $((10-6)) "$_Dbg_listline"
}

abs_top_srcdir=/src/external-vcs/sourceforge/bashdb
# Make sure $abs_top_srcdir has a trailing slash
abs_top_srcdir=${abs_top_srcdir%%/}/
. ${abs_top_srcdir}test/unit/helper.sh
. $abs_top_srcdir/lib/list.sh
set -- # reset $# so shunit2 doesn't get confused.

[[ $0 == ${BASH_SOURCE} ]] && . ${shunit_file}
