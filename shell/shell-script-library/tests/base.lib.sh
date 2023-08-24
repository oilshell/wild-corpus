#!/bin/sh -eu

. ../base.lib.sh
. ../fs.lib.sh
. ../string.lib.sh
. ../bool.lib.sh

test_k_tool_name() {
	assertEquals "Tool name auto detect is correct" "$(basename "$0")" "$(k_tool_name)"
	assertEquals "Tool name variable is correct" "sometoolname" "$(KOALEPHANT_TOOL_NAME=sometoolname k_tool_name)"
}

test_k_tool_version() {
	assertEquals "Tool version defaults to 1.0.0" "1.0.0" "$(k_tool_version)"
	assertEquals "Tool version variable is correct" "2.3.1" "$(KOALEPHANT_TOOL_VERSION=2.3.1 k_tool_version)"

}
#
#test_k_tool_year() {
#
#}
#
#test_k_tool_owner() {
#
#}
#
#test_k_tool_description() {
#
#}
#
#test_k_tool_options() {
#
#}
#
#test_k_tool_options_arguments() {
#
#}
#
#test_k_tool_arguments() {
#
#}
#
#test_k_tool_usage() {
#
#}
#
#test_k_tool_debug() {
#
#}
#
#test_k_version() {
#
#}
#
#test_k_usage() {
#
#}
#
#test_k_require_root() {
#
#}
#
#test_k_debug() {
#
#}
