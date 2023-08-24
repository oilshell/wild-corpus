#@IgnoreInspection BashAddShebang
# Boolean functionality (Koalephant Shell Script Library)
# Version: 2.0.0
# Copyright: 2014-2017, Koalephant Co., Ltd
# Author: Stephen Reay <stephen@koalephant.com>, Koalephant Packaging Team <packages@koalephant.com>

# Parse a string into 'true' or 'false'
# 'true' values are 'on', 'true', 'yes', 'y' and '1', regardless of case
# 'false' values are 'off', 'false' 'no', 'n' and '0', regardless of case
#
# Input:
# $1 - the string to parse
# $2 - the default value to return if neither true or false is matched
#
# Output:
# either 'true' or 'false', or the default value if specified
k_bool_parse() {
	local value
	local default="${2-}"
	if value="$(k_bool_parse_error "$1")"; then
		echo "${value}"
	else
		echo "$(k_bool_parse "${default}" false)"
	fi
}

# Parse a string into 'true' or 'false' or error
# 'true' values are 'on', 'true', 'yes', 'y' and '1', regardless of case
# 'false' values are 'off', 'false' 'no', 'n' and '0', regardless of case
#
# Input:
# $1 - the string to parse
#
# Output:
# either 'true' or 'false'
#
# Return:
# 0 if a valid bool value is given, 1 if not
k_bool_parse_error() {
	local value="$1"
	case "$(k_string_lower "${value}")" in
		on|true|yes|y|1)
			echo true
		;;

		off|false|no|n|0)
			echo false
		;;

		*)
			return 1
		;;

	esac
}

# Test a variable for truthiness.
# Uses (#k_bool_parse) to parse input
#
# Input:
# $1 - the variable to test
# $2 - the default value to test if neither true or false is matched
#
# Return:
# 0 if true, 1 if not
#
# Example:
# if k_string_test_bool "${optionValue}"; then
# 	do_something
# fi
k_bool_test() {
	[ "$(k_bool_parse "$@")" = true ]
}

# Test a variable for booelan-ness
# Uses (#k_bool_parse) to parse input
#
# Input:
# $1 - the variable to test
#
# Return:
# 0 if a valid boolean value, 1 if not
k_bool_valid() {
	k_bool_parse_error "$1" > /dev/null
}
