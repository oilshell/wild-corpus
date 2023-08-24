#!/bin/sh -eux

. ../config.lib.sh

config_file="./test-conf.conf"

test_k_config_sections() {
	assertEquals "Section Names" "$(printf "section\nsection2")" "$(k_config_sections "${config_file}")"
	assertEquals "Section Names under [section2]" "baz" "$(k_config_sections "${config_file}" "section2")"
	assertEquals "Section Names under [section3]" "" "$(k_config_sections "${config_file}" "section3")"
}


#test_k_config_keys() {
#
#}
#
#test_k_config_read() {
#	${_ASSERT_EQUALS_} "ABC to lower" abc "$(k_string_lower ABC)"
#}
#
#test_k_config_read_error() {
#
#}
#
#test_k_config_read_string() {
#
#}
#
#test_k_config_read_bool() {
#
#}
#
#test_k_config_test_bool() {
#
#}
