#!/bin/sh

. ../string.lib.sh
. ../bool.lib.sh


test_k_bool_parse() {
	assertEquals "true is true" true "$(k_bool_parse true)"
	assertEquals "yes is true" true "$(k_bool_parse yes)"
	assertEquals "1 is true" true "$(k_bool_parse 1)"
	assertEquals "on is true" true "$(k_bool_parse on)"
}