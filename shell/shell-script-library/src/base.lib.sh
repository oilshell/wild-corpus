#@IgnoreInspection BashAddShebang
# Base app functionality (Koalephant Shell Script Library)
# Version: 2.0.0
# Copyright: 2014-2017, Koalephant Co., Ltd
# Author: Stephen Reay <stephen@koalephant.com>, Koalephant Packaging Team <packages@koalephant.com>

# Base Shell Library version
KOALEPHANT_LIB_VERSION="2.0.0"
readonly KOALEPHANT_LIB_VERSION

# Base directory for the installed Library
KOALEPHANT_LIB_PATH="${KOALEPHANT_LIB_PATH:-PREFIX/LIBRARY_PATH}"
readonly KOALEPHANT_LIB_PATH

# Get the tool name
#
# Input:
# $KOALEPHANT_TOOL_NAME - explicit name used as-is if set
# $0 - the script name is stripped of directory components and any '.sh' suffix
#
# Output:
# the tool name
k_tool_name() {
	if [ -n "${KOALEPHANT_TOOL_NAME:-}" ]; then
		printf "%s" "${KOALEPHANT_TOOL_NAME}"
	else
		k_fs_basename "${0}" ".sh"
	fi
}

# Get the tool version
#
# Input:
# $KOALEPHANT_TOOL_VERSION - explicit version used as-is if set. Default is 1.0.0 if not set
#
# Output:
# the tool version
k_tool_version() {
	printf "%s" "${KOALEPHANT_TOOL_VERSION:-1.0.0}"
}

# Get the tool copyright year
#
# Input:
# $KOALEPHANT_TOOL_YEAR - explicit copyright year used as-is if set. Default is current year if not set
#
# Output:
# the tool copyright year
k_tool_year() {
	printf "%s" "${KOALEPHANT_TOOL_YEAR:-$(date +%Y)}"
}

# Get the tool copyright owner
#
# Input:
# $KOALEPHANT_TOOL_OWNER - explicit copyright owner used as-is if set. Default is 'Koalephant Co., Ltd' if not set
#
# Output:
# the tool copyright owner
k_tool_owner() {
	printf "%s" "${KOALEPHANT_TOOL_OWNER:-Koalephant Co., Ltd}"
}

# Get the tool description
#
# Input:
# $KOALEPHANT_TOOL_DESCRIPTION - tool description used as-is
#
# Output:
# the tool description
k_tool_description() {
	printf "%s" "${KOALEPHANT_TOOL_DESCRIPTION:-}"
}

# Get the tool options descriptions
#
# Input:
# $KOALEPHANT_TOOL_OPTIONS - tool options descriptions used as-is
#
# Output:
# the tool options descriptions
k_tool_options() {
	printf "%s" "${KOALEPHANT_TOOL_OPTIONS:-}"
}


# Get the tool option(s) argument(s)
# Shows output if (#k_tool_options) returns non-empty content
#
# Input:
# $KOALEPHANT_TOOL_OPTIONS_ARGUMENTS - explicit tool option(s) argument(s) used as-is. Default is '[options]' if not set
#
# Output:
# the tool option(s) argument(s)
k_tool_options_arguments() {
	if [ -n "$(k_tool_options)" ]; then
		printf " %s" "${KOALEPHANT_TOOL_OPTIONS_ARGUMENTS:-[options]}"
	fi
}

# Get the tool arguments
#
# Input:
# $KOALEPHANT_TOOL_ARGUMENTS - tool arguments used as-is
#
# Output:
# the tool arguments
k_tool_arguments() {
	printf " %s" "${KOALEPHANT_TOOL_ARGUMENTS:-}"
}

# Get the tool usage
# uses (#k_tool_name), (#k_tool_options_arguments) and (#k_tool_arguments)
#
# Output:
# the tool usage
k_tool_usage() {
	printf "Usage: %s%s%s\n" "$(k_tool_name)" "$(k_tool_options_arguments)" "$(k_tool_arguments)"
}

# Show the current tool version
# uses (#k_tool_name), (#k_tool_version) (#k_tool_year) and (#k_tool_owner)
#
# Output:
# the version information
k_version() {
	printf "%s version %s \nCopyright (c) %s, %s\n" "$(k_tool_name)" "$(k_tool_version)" "$(k_tool_year)" "$(k_tool_owner)"
}

# Show the Usage info for this script
# uses (#k_tool_name), (#k_tool_description) and (#k_tool_usage) and (#k_tool_options)
#
# Output:
# the usage information
k_usage() {
	printf "%s\n" "$(k_tool_usage)"
	printf "%s\n\n" "$(k_tool_description)"
	printf "%s\n" "$(k_tool_options)"
}

# Check if the running (effective) user is root, and error if not
#
# Input:
# $1 - an extra error message to show if the current user is not root
#
# Output:
# Any additional message provided in `$1` plus a standard error message, if run by a non-root user.
#
# Return:
# 0 when effective user is root, 1 otherwise
k_require_root() {
	if [ "$(id -u)" -ne 0 ]; then
		if [ -n "${1}" ]; then
			k_log_err "${1}"
		fi
		k_log_err "$(k_tool_name) must be run as root"
		return 1
	fi
}

# Check that an option has an argument specified.
#
# Input:
# $1 - the option name
# $2 - the next argument the tool was invoked with
#
# Output:
# the argument value if valid
#
# Return:
# 0 on success, 1 otherwise
k_option_requires_arg() {
	if [ -n "${2:-}" ] && ! k_string_starts_with "-" "${2}"; then
		printf '%s' "${2}"
	else
		k_log_err "Error, ${1} requires an argument"
		k_usage
		return 1
	fi
}

# Check whether an option has an optional argument specified.
#
# Input:
# $1 - the option name
# $2 - the next argument the tool was invoked with
#
# Output:
# the argument value if specified
k_option_optional_arg() {
	local tool="$1"
	if [ -n "${2:-}" ] && ! k_string_starts_with "-" "${2}"; then
		printf '%s' "${2}"
	fi
}

# Log level EMERG - system is unusable
KOALEPHANT_LOG_LEVEL_EMERG=1
readonly KOALEPHANT_LOG_LEVEL_EMERG

# Log level ALERT - action must be taken immediately
KOALEPHANT_LOG_LEVEL_ALERT=2
readonly KOALEPHANT_LOG_LEVEL_ALERT

# Log level CRIT - critical conditions
KOALEPHANT_LOG_LEVEL_CRIT=3
readonly KOALEPHANT_LOG_LEVEL_CRIT

# Log level ERR - error conditions
KOALEPHANT_LOG_LEVEL_ERR=4
readonly KOALEPHANT_LOG_LEVEL_ERR

# Log level WARNING - warning conditions
KOALEPHANT_LOG_LEVEL_WARNING=5
readonly KOALEPHANT_LOG_LEVEL_WARNING

# Log level NOTICE - normal, but significant, condition
KOALEPHANT_LOG_LEVEL_NOTICE=6
readonly KOALEPHANT_LOG_LEVEL_NOTICE

# Log level INFO - informational message
KOALEPHANT_LOG_LEVEL_INFO=7
readonly KOALEPHANT_LOG_LEVEL_INFO

# Log level DEBUG - debug-level message
KOALEPHANT_LOG_LEVEL_DEBUG=8
readonly KOALEPHANT_LOG_LEVEL_DEBUG

# Check if a value is a valid log level
#
# Input:
# $1 - log level value to check
k_log_level_valid() {
	[ "$1" -ge ${KOALEPHANT_LOG_LEVEL_EMERG} ] && [ "$1" -le ${KOALEPHANT_LOG_LEVEL_DEBUG} ]
}

# Get/Set the current log level
#
# Input:
# $1 - if provided, set the active log level to this value
# $KOALEPHANT_LOG_LEVEL_ACTIVE - used as explicit log level if set. Default is ($#KOALEPHANT_LOG_LEVEL_ERR) if not set
#
# Output:
# the active log level
k_log_level() {
	if [ $# -eq 1 ]; then
	 	if ! k_log_level_valid "$1"; then
			printf "%s" "Invalid log level specified" >&2
			return 1
		else
			KOALEPHANT_LOG_LEVEL_ACTIVE="$1"
		fi
	fi

	printf '%d' "${KOALEPHANT_LOG_LEVEL_ACTIVE:-$KOALEPHANT_LOG_LEVEL_ERR}"
}

# Get the log level name from a log level value
k_log_level_name() {
	if ! k_log_level_valid "$1"; then
		printf "%s" "Invalid log level specified" >&2
		return 1
	fi
	case "${1}" in
		${KOALEPHANT_LOG_LEVEL_EMERG})
			printf "%s" "emerg"
		;;

		${KOALEPHANT_LOG_LEVEL_ALERT})
			printf "%s" "alert"
		;;

		${KOALEPHANT_LOG_LEVEL_CRIT})
			printf "%s" "crit"
		;;

		${KOALEPHANT_LOG_LEVEL_ERR})
			printf "%s" "err"
		;;

		${KOALEPHANT_LOG_LEVEL_WARNING})
			printf "%s" "warning"
		;;

		${KOALEPHANT_LOG_LEVEL_NOTICE})
			printf "%s" "notice"
		;;

		${KOALEPHANT_LOG_LEVEL_INFO})
			printf "%s" "info"
		;;

		${KOALEPHANT_LOG_LEVEL_DEBUG})
			printf "%s" "debug"
		;;
	esac
}

# Check if logs should be set to syslog
#
# Input:
# $KOALEPHANT_LOG_SYSLOG - used as flag to enable syslog
#
# Return:
# 0 if syslog should be used, 1 otherwise
k_log_syslog() {
	k_bool_test "${KOALEPHANT_LOG_SYSLOG:-}"
}

# Log a message according to a syslog level
#
# Input:
# $1 - the syslog level constant to use. One of the `KOALEPHANT_LOG_LEVEL_*` constants
k_log_message() {
	local level="$1"
	shift
	local message="$*"

	if k_log_level_valid "$level" && [ $(k_log_level) -ge "${level}" ]; then
		printf "%s\n" "$@" >&2
		if k_log_syslog; then
			/usr/bin/logger --tag "$(k_tool_name)" --id $$ --priority "user.$(k_log_level_name "${level}")" -- "$@"
		fi
	fi
}

# Log a message at syslog-level EMERG
#
# Input:
# $1...n - the message string
k_log_emerg() {
	k_log_message ${KOALEPHANT_LOG_LEVEL_EMERG} "$@"
}

# Log a message at syslog-level ALERT
#
# Input:
# $1...n - the message string
k_log_alert() {
	k_log_message ${KOALEPHANT_LOG_LEVEL_ALERT} "$@"
}

# Log a message at syslog-level CRIT
#
# Input:
# $1...n - the message string
k_log_crit() {
	k_log_message ${KOALEPHANT_LOG_LEVEL_CRIT} "$@"
}

# Log a message at syslog-level ERR
#
# Input:
# $1...n - the message string
k_log_err() {
	k_log_message ${KOALEPHANT_LOG_LEVEL_ERR} "$@"
}

# Log a message at syslog-level WARNING
#
# Input:
# $1...n - the message string
k_log_warning() {
	k_log_message ${KOALEPHANT_LOG_LEVEL_WARNING} "$@"
}

# Log a message at syslog-level NOTICE
#
# Input:
# $1...n - the message string
k_log_notice() {
	k_log_message ${KOALEPHANT_LOG_LEVEL_NOTICE} "$@"
}

# Log a message at syslog-level INFO
#
# Input:
# $1...n - the message string
k_log_info() {
	k_log_message ${KOALEPHANT_LOG_LEVEL_INFO} "$@"
}

# Log a message at syslog-level DEBUG
#
# Input:
# $1...n - the message string
k_log_debug() {
	k_log_message ${KOALEPHANT_LOG_LEVEL_DEBUG} "$@"
}
