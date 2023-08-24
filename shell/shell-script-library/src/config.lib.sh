#@IgnoreInspection BashAddShebang
# Config file functionality (Koalephant Shell Script Library)
# Version: 2.0.0
# Copyright: 2017, Koalephant Co., Ltd
# Author: Stephen Reay <stephen@koalephant.com>, Koalephant Packaging Team <packages@koalephant.com>

# Run a cfget command
#
# Input:
# $1 - the config file
# $2...n - extra arguments for cfget
#
# Output:
# The result from cfget
#
# Return:
# The cfget return code
k_config_command() {
	local file="$1"
	shift

	CFGET_BIN --plugin "${KOALEPHANT_LIB_PATH}/cfget-plugins/" --format nestedini --cfg "${file}" --quiet "$@"
}

# Get config sections
#
# Input:
# $1 - the config file
# $2 - the config root to work from
#
# Output:
# the section names, one per line
k_config_sections() {
	local file="$1"
	local root=""
	if [ -n "${2:-}" ]; then
		root="--root ${2}"
	fi

	k_config_command "${file}" --dump sections ${root} || true
}

# Get config keys
#
# Input:
# $1 - the config file
# $2 - the config root to work from
#
# Output:
# the key names, one per line
k_config_keys() {
	local file="$1"
	local root=""
	if [ -n "${2:-}" ]; then
		root="--root ${2}"
	fi

	k_config_command "${file}" --dump keys ${root}
}

# Read a Config Value
# Unlike (#k_config_read_error), this function will not error if the config key is not found
#
# Input:
# $1 - the config file
# $2 - the key to read
# $3 - the config root to work from
#
# Output:
# the value of the key, if it exists
k_config_read() {
	k_config_read_error "$@" || true
}

# Read a Config Value, or error
#
# Input:
# $1 - the config file
# $2 - the key to read
# $3 - the config root to work from
#
# Output:
# the value of the key, if it exists
#
# Return:
# 0 on success, 1 on error
k_config_read_error() {
	local file="$1"
	local key="$2"
	local root=""
	if [ -n "${3:-}" ]; then
		root="--root ${3}"
	fi


	k_config_command "${file}" ${root} "${key}"
}

# Get a Config value or a default value
#
# Input:
# $1 - the config file
# $2 - the key to read
# $3 - the default value (defaults to empty string)
# $4 - the config root to work from
#
# Output:
# the value of the key, or the default value
k_config_read_string() {
	local file="$1"
	local key="$2"
	local default="${3:-}"
	local root="${4:-}"

	local value="$(k_config_read "$file" "$key" "${root}")"

	printf "%s" "${value:-$default}"
}

# Get a 'Boolean' Config value or a default value
#
# Input:
# $1 - the config file
# $2 - the key to read
# $3 - the default value (defaults to empty string)
# $4 - the config root to work from
#
# Output:
# `true`, `false` or the default value given if the config value cannot be parsed using (#k_bool_parse)
k_config_read_bool() {
	local file="$1"
	local key="$2"
	local default="${3:-}"
	local root="${4:-}"

	k_bool_parse "$(k_config_read "${file}" "${key}" "${root}")" "${default}"
}

# Test a 'Boolean' Config value or a default value
#
# Input:
# $1 - the config file
# $2 - the key to read
# $3 - the default value (defaults to empty string)
# $4 - the config root to work from
#
# Return:
# 0 if either the config value or the default value is true, 1 otherwise
k_config_test_bool() {
	local file="$1"
	local key="$2"
	local default="${3:-}"
	local root="${4:-}"

	k_bool_test "$(k_config_read_string "${file}" "${key}" "$(k_bool_parse "${default}")" "${root}")"
}

# Get a 'keyword' Config value or a default value
#
# Input:
# $1 - the config file
# $2 - the key to read
# $3 - the default value
# $4 - the config root to work from
# $5...n - the list of valid keyword values
#
# Output:
# the valid keyword or default value
k_config_read_keyword() {
	local file="$1"
	local key="$2"
	local default="$3"
	local root="$4"

	shift 4

	k_string_keyword "$(k_config_read_string "${file}" "${key}" "${default}" "${root}")" "$@" "$default"
}
