#!/bin/sh

. ../string.lib.sh
. ../bool.lib.sh

test_k_string_contains() {
	assertTrue "241345 contains 1" "k_string_contains 1 241345"

	assertTrue "d3dabcd contains a" "k_string_contains a d3dabcd"

	assertTrue "-- contains -" "k_string_contains - --"

	assertFalse "acd does not contain b" "k_string_contains b acd"
}
test_k_string_get_line() {
	local line1="Hello world!"
	local line2="This is some text"
	local line3="And this is more"
	local str="$(printf "%s\n%s\n%s" "${line1}" "${line2}" "${line3}")"

	assertEquals "${line1}" "$(k_string_get_line 1 "${str}")"
	assertEquals "${line2}" "$(k_string_get_line 2 "${str}")"
	assertEquals "${line3}" "$(k_string_get_line 3 "${str}")"

}
test_k_string_ends_with() {

	assertTrue "12345 ends with 5" "k_string_ends_with 5 12345"
	assertFalse "12345 does not end with 6" "k_string_ends_with 6 12345"

	assertTrue "abcd ends with d" "k_string_ends_with d abcd"


	assertTrue "-- ends with -" "k_string_ends_with - --"

	assertFalse "- does not end with --" "k_string_ends_with -- -"

	assertFalse "abcd does not end with b" "k_string_ends_with b abcd"
}
test_k_string_starts_with() {
	assertTrue "12345 starts with 1" "k_string_starts_with 1 12345"

	assertTrue "abcd starts with a" "k_string_starts_with a abcd"

	assertTrue "-- starts with -" "k_string_starts_with - --"

	assertFalse "- does not start with --" "k_string_starts_with -- -"

	assertFalse "abcd does not start with b" "k_string_starts_with b abcd"
}
test_k_string_lower() {
	assertEquals "ABC to lower" abc "$(k_string_lower ABC)"
	assertEquals "Abc to lower" abc "$(k_string_lower Abc)"
	assertEquals "123 to lower" 123 "$(k_string_lower 123)"
	assertEquals "D-e+F to lower" d-e+f "$(k_string_lower D-e+F)"
}

test_k_string_upper() {
	assertEquals "abc to upper" ABC "$(k_string_upper abc)"
	assertEquals "Abc to upper" ABC "$(k_string_upper Abc)"
	assertEquals "123 to upper" 123 "$(k_string_upper 123)"
	assertEquals "D-e+F to upper" D-E+F "$(k_string_upper D-e+F)"
}

test_k_string_pad_right() {
	assertEquals "Pad to 8 spaces" "foo     " "$(k_string_pad_right 8 foo)"
}

test_k_string_pad_left() {
	assertEquals "Pad to 8 spaces" "     foo" "$(k_string_pad_left 8 foo)"
}

test_k_string_remove_start() {
	assertEquals "abc remove a from start" bc "$(k_string_remove_start a abc)"
	assertEquals "aabc remove a from start" abc "$(k_string_remove_start a aabc)"
	assertEquals "abc remove b from start" abc "$(k_string_remove_start b abc)"
	assertEquals "abc remove c from start" abc "$(k_string_remove_start c abc)"
	assertEquals "abc remove d from start" abc "$(k_string_remove_start d abc)"
}

test_k_string_remove_end() {
	assertEquals "abc remove a from end" abc "$(k_string_remove_end a abc)"
	assertEquals "abc remove b from end" abc "$(k_string_remove_end b abc)"
	assertEquals "abc remove c from end" ab "$(k_string_remove_end c abc)"
	assertEquals "abc remove d from end" abc "$(k_string_remove_end d abc)"
}

test_k_string_join() {
	assertEquals "a joined by hyphen" "a" "$(k_string_join "-" a)"
	assertEquals "a, b joined by hyphen" "a-b" "$(k_string_join "-" a b)"
	assertEquals "a, b, c joined by hyphen" "a-b-c" "$(k_string_join "-" a b c)"
	assertEquals "a, b, c joined by nothing" "abc" "$(k_string_join "" a b c)"
}

test_k_string_trim() {
	assertEquals "'   a' trimmed" "a" "$(k_string_trim "   a")"
	assertEquals "'a	' trimmed" "a" "$(k_string_trim "a	")"
	assertEquals "'   a   ' trimmed" "a" "$(k_string_trim "   a   ")"
	assertEquals "'   a b c	' trimmed" "a b c" "$(k_string_trim "   a b c	")"
}