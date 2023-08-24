#@IgnoreInspection BashAddShebang
# String functionality (Koalephant Shell Script Library)
# Version: 2.0.0
# Copyright: 2014-2017, Koalephant Co., Ltd
# Author: Stephen Reay <stephen@koalephant.com>, Koalephant Packaging Team <packages@koalephant.com>

# Get a line from a multiline variable
#
# Input:
# $1 - the line number to fetch
# $2...n - all remaining arguments are treated as the text to search
#
# Output:
# The text on the specified line
#
k_string_get_line() {
	local lineNo delim

	if [ $# -eq 0 ]; then
		k_log_err "k_string_get_line requires least 1 argument"
		return 1
	fi

	delim="$(printf '\n ')"
	lineNo="$1"

	shift

	echo "$@" | cut -d "${delim% }" -f "${lineNo}"
}

# Right Pad a string to the given length
#
# Input:
# $1 - the length to pad to
# $n - all remaining arguments are treated as the text to pad

# Output:
# The string, with padding applied
k_string_pad_right() {
	local length text

	if [ $# -eq 0 ]; then
		k_log_err "k_string_pad_right requires least 1 argument"
		return 1
	fi

	length="$1"
	shift

	printf "%-${length}s" "$*"
}

# Left Pad a string to the given length
#
# Input:
# $1 - the length to pad to
# $n - all remaining arguments are treated as the text to pad
# PAD_CHAR - if set, the character to pad with (defaults to space)

# Output:
# The string, with padding applied
k_string_pad_left() {
	local length text

	if [ $# -eq 0 ]; then
		k_log_err "k_string_pad_left requires least 1 argument"
		exit 1
	fi

	length="$1"
	shift

	printf "%+${length}s" "$*"
}

# Convert a string to lower case
#
# Input:
# $1...n - all arguments are treated as the text to convert
#
# Output:
# The string, converted to lower case
k_string_lower() {
	printf "%s" "$*" | tr '[:upper:]' '[:lower:]'
}

# Convert a string to upper case
#
# Input:
# $1...n - all arguments are treated as the text to convert
#
# Output:
# The string, converted to upper case
k_string_upper() {
	printf "%s" "$*" | tr '[:lower:]' '[:upper:]'
}

# Test if a string contains the given substring
#
# Input:
# $1 - the substring to check for
# $2...n - all arguments are treated as the string to check in
#
# Return:
# 0 if substring is found, 1 if not
k_string_contains() {
	local substring string
	if [ $# -lt 2 ]; then
		k_log_err "k_string_contains requires least 2 arguments"
		exit 1
	fi

	substring="${1}"
	shift
	string="$*"

	if [ "${#string}" -gt 0 ] && [ "${string%*${substring}*}" != "${string}" ]; then
		return 0
	fi

	return 1
}

# Test if a string starts with the given substring
#
# Input:
# $1 - the substring to check for
# $2...n - all arguments are treated as the string to check in
#
# Return:
# 0 if the string starts with substring, 1 if not
k_string_starts_with() {
	local substring string
	if [ $# -lt 2 ]; then
		k_log_err "k_string_starts_with requires least 2 arguments"
		exit 1
	fi

	substring="${1}"
	shift
	string="$*"

	if [ "${#string}" -gt 0 ] && [ "${string%%${substring}*}" = "" ]; then
		return 0
	fi

	return 1
}

# Test if a string ends with the given substring
#
# Input:
# $1 - the substring to check for
# $2...n - all arguments are treated as the string to check in
#
# Return:
# 0 if the string ends with substring, 1 if not
k_string_ends_with() {
	local substring string
	if [ $# -lt 2 ]; then
		k_log_err "k_string_ends_with requires least 2 arguments"
		exit 1
	fi

	substring="${1}"
	shift
	string="$*"

	if [ "${#string}" -gt 0 ] && [ "${string##*${substring}}" = "" ]; then
		return 0
	fi

	return 1
}

# Remove a substring from the start of a string
#
# Input:
# $1 - the substring to remove
# $2...n - all arguments are treated as the string to operate on
#
# Output:
# The string with substring removed from the start
k_string_remove_start() {
	local substring string greedy=false

	if [ "$(k_bool_parse "${REMOVE_GREEDY:-}")" = true ]; then
		greedy=true
	fi

	if [ $# -lt 2 ]; then
		k_log_err "k_string_remove_start requires least 2 arguments"
		exit 1
	fi

	substring="${1}"
	shift
	string="$*"

	if [ ${greedy} = true ]; then
		printf "%s" "${string##${substring}}"
	else
		printf "%s" "${string#${substring}}"
	fi
}

# Remove a substring from the end of a string
#
# Input:
# $1 - the substring to remove
# $2...n - all arguments are treated as the string to operate on
# REMOVE_GREEDY - set to `true` to match the longest pattern possible
#
# Output:
# The string with substring removed from the end
k_string_remove_end() {
	local substring string greedy=false

	if [ "$(k_bool_parse "${REMOVE_GREEDY:-}")" = true ]; then
		greedy=true
	fi

	if [ $# -lt 2 ]; then
		k_log_err "k_string_remove_start requires least 2 arguments"
		exit 1
	fi

	substring="${1}"
	shift
	string="$*"

	if [ ${greedy} = true ]; then
		printf "%s" "${string%%${substring}}"
	else
		printf "%s" "${string%${substring}}"
	fi

}

# Join strings with an optional separator
#
# Input:
# $1 - the separator string
# $2...n - the strings to join
#
# Output:
# the strings joined by the separator
#
# Example:
# k_string_join "-" this is a nice day # "this-is-a-nice-day"
k_string_join() {
	local separator="${1-}"
	shift
	k_string_remove_end "${separator}" "$(printf "%s${separator}" "$@")"
}

# Remove leading and trailing whitespace from strings
#
# Input:
# $1...n - the strings to join
#
# Output:
# the strings with leading/trailing whitespace removed
k_string_trim() {
	printf "%s" "$*" | sed -e "s/^[[:space:]]*//g; s/[[:space:]]*$//g;"
}

# Check if the given keyword is in the list of valid keywords, or error
#
# Input:
# $1 - the input to check
# $2...n - the list of valid keywords
#
# Output:
# the keyword if valid
#
# Return:
# 0 if keyword is valid, 1 if not
k_string_keyword_error() {
	local input="${1}"
	shift
	while [ $# -gt 0 ]; do
		if [ "${input}" = "${1}" ]; then
			printf "$1"
			return 0
		fi
		shift
	done

	return 1
}

# Get the selected keyword from a list, or default
#
# Input:
# $1 - the input to check
# $2...n - the list of valid keywords. The last value is used as the default if none match
#
# Output:
# the valid keyword or default
k_string_keyword() {
	local value
	if value="$(k_string_keyword_error "$@")"; then
		echo "${value}"
	else
		shift $(($#-1))
		echo "$1"
	fi
}