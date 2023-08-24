#!/bin/sh -eu
# Generate Markdown documentation from a 'shelldoc' documented shell script
# Version: 2.0.0
# Copyright: 2017, Koalephant Co., Ltd
# Author: Stephen Reay <stephen@koalephant.com>, Koalephant Packaging Team <packages@koalephant.com>

# Generate Markdown documentation from a 'shelldoc' documented shell script
#
# Input:
# $1 - file to process
#
# Output:
# Markdown formatted documentation
#
# Example:
# k_shell_doc file1.sh > file1.md
k_shell_doc() {

	local KOALEPHANT_TOOL_DESCRIPTION="Generate Markdown documentation from a 'shelldoc' documented shell script"
	local KOALEPHANT_TOOL_VERSION="1.0.0"
	local KOALEPHANT_TOOL_OPTIONS="$(cat <<-EOT
		Options:

		 -h, --help           show this help
		 -v, --version        show the version
		 -V, --verbose        show verbose output
		 -D, --debug          show debug output
		 -q, --quiet          suppress all output except errors

EOT
	)"

	local KOALEPHANT_TOOL_ARGUMENTS="file"

	. ./base.lib.sh
	. ./string.lib.sh
	. ./bool.lib.sh
	. ./fs.lib.sh

	k_log_level ${KOALEPHANT_LOG_LEVEL_NOTICE} > /dev/null

	local TMP_FUNC_DESCRIPTION="func-description"
	readonly TMP_FUNC_DESCRIPTION

	local TMP_FUNC_INPUT="func-input"
	readonly TMP_FUNC_INPUT

	local TMP_FUNC_OUTPUT="func-output"
	readonly TMP_FUNC_OUTPUT

	local TMP_FUNC_RETURN="func-return"
	readonly TMP_FUNC_RETURN

	local TMP_FUNC_EXAMPLE="func-example"
	readonly TMP_FUNC_EXAMPLE

	local tmpDir="$(k_fs_temp_dir)"
	readonly tmpDir

	local newLineWSpace="$(printf '\n ')"
	readonly newLineWSpace

	local newLine="${newLineWSpace% }"
	readonly newLine

	local file=""
	local headerBlock=""
	local headerDescription=""
	local headerMode=true

	local funcMode=false
	local functionSegment="description"

	tmp_string_file() {
		local name="$1"
		printf "%s/%s" "${tmpDir}" "${name}"
	}

	tmp_string_get() {
		local name="$1"
		cat "$(tmp_string_file "${name}")"
	}

	tmp_string_append() {
		local name="$1"
		local string="$2"
		printf "%s\n" "${string}" >> "$(tmp_string_file "${name}")"
	}

	tmp_string_set() {
		local name="$1"
		local string="$2"
		printf "%s\n" "${string}" > "$(tmp_string_file "${name}")"
	}

	tmp_string_clear() {
		local name="$1"
		printf "" > "$(tmp_string_file "${name}")"
	}

	tmp_string_exists() {
		local name="$1"
		[ -s "$(tmp_string_file "${name}")" ]
	}

	add_header_property() {
		local name="$1"
		local value="$2"
		local line="$(printf "%s: %s" "${name}" "${value}")"

		k_log_info "Adding header property: ${name}"
		if [ -n "${headerBlock}" ]; then
			line="${newLine}${line}"
		fi

		headerBlock="${headerBlock}${line}"
	}

	add_header_description() {
		local line="$1"
		k_log_info "Adding header description: ${line}"

		if [ -n "${headerDescription}" ]; then
			line="${newLineWSpace}${line}"
		fi


		headerDescription="${headerDescription}${line}"
	}

	print_headers() {
		add_header_property "description" "${headerDescription}"
		local block="---"
		printf "%s\n%s\n%s\n\n" "${block}" "${headerBlock}" "${block}"
	}

	parse_header_line() {
		local line="$1" property value

		if ! k_string_starts_with "#" "${line}"; then
			k_log_info "End of file header detected"
			print_headers
			headerMode=false
			return
		fi

		line="$(k_string_remove_start "#" "${line}")"

		case "$line" in

			@Ignore*|!*)
			;;

			*:*)
				property="$(k_string_remove_end ":*" "${line}")"
				value="$(k_string_trim "$(k_string_remove_start "${property}:" "${line}")")"
				add_header_property "$(k_string_lower "$(k_string_trim "${property}")")" "${value}"
			;;

			*)
				add_header_description "$(k_string_trim "$line")"
			;;
		esac
	}

	parse_function_input() {
		tmp_string_append "${TMP_FUNC_INPUT}" "$(format_function_input "$1")"
	}
	parse_function_output() {
		tmp_string_append "${TMP_FUNC_OUTPUT}" "$(k_string_trim "$1")"
	}

	parse_function_return() {
		tmp_string_append "${TMP_FUNC_RETURN}" "$(k_string_trim "$1")"
	}

	parse_function_description() {
		tmp_string_set "${TMP_FUNC_DESCRIPTION}" "$(format_function_links "$(k_string_trim "${1}")")"
	}

	parse_function_example() {
		tmp_string_append "${TMP_FUNC_EXAMPLE}" "$1"
	}

	format_function_input() {
		local line="$1"
		local name="$(k_string_remove_end " - *" "${line}")"
		local description="$(k_string_trim "$(k_string_remove_start "${name} - " "${line}")")"
		printf " * \`%s\` - %s\n" "$(k_string_trim "$name")" "$(format_function_links "$description")"
	}

	format_function_links() {
		printf "%s" "$1" | sed -E -e 's/\(([^#]*)#([A-Za-z_]{1,})\)/[`\1\2`](#\2)/g'
	}

	print_function_title() {
		printf '### `%s` {#%s}\n%s\n\n' "$1" "${2:-${1}}" "$(tmp_string_get "${TMP_FUNC_DESCRIPTION}")"
	}

	print_function_input() {
		if tmp_string_exists "${TMP_FUNC_INPUT}"; then
			printf '#### Input:\n%s\n\n' "$(tmp_string_get "${TMP_FUNC_INPUT}")"
		fi
	}

	print_function_output() {
		if tmp_string_exists "${TMP_FUNC_OUTPUT}"; then
			printf '#### Output:\n%s\n\n' "$(tmp_string_get "${TMP_FUNC_OUTPUT}")"
		fi
	}

	print_function_return() {
		if tmp_string_exists "${TMP_FUNC_RETURN}"; then
			printf '#### Return:\n%s\n\n' "$(tmp_string_get "${TMP_FUNC_RETURN}")"
		fi
	}

	print_function_example() {
		if tmp_string_exists "${TMP_FUNC_EXAMPLE}"; then
			printf '#### Example:\n~~~sh\n%s\n~~~\n\n' "$(tmp_string_get "${TMP_FUNC_EXAMPLE}")"
		fi
	}

	parse_body_line() {
		local line="$1"
		local paddedLine=""

		if [ "${#line}" -eq 0 ]; then
			return
		fi

		if ! k_string_starts_with "#" "${line}"; then
			if [ ${funcMode} != true ]; then
				return
			fi

			local name
			local doFuncBits=false
			local identifier=""

			if k_string_contains "()" "${line}"; then
				name="$(k_string_remove_end "()*" "${line}")"
			else
				identifier="$(k_string_remove_end "=*" "${line}")"
				name="\$${identifier}"
			fi

			print_function_title "${name}" "${identifier}"
			print_function_input
			print_function_output
			print_function_return
			print_function_example

			funcMode=false
			functionSegment=description

			tmp_string_clear "${TMP_FUNC_DESCRIPTION}"
			tmp_string_clear "${TMP_FUNC_INPUT}"
			tmp_string_clear "${TMP_FUNC_OUTPUT}"
			tmp_string_clear "${TMP_FUNC_RETURN}"
			tmp_string_clear "${TMP_FUNC_EXAMPLE}"

		else
			funcMode=true
			paddedLine="$(k_string_remove_start "\#" "${line}")"
			line="$(k_string_trim "${paddedLine}")"

			if [ "${#line}" -eq 0 ]; then
				return
			fi

			case "${line}" in
				@Ignore*|@TODO*|@Todo*)
					return
				;;

				Input:*)
					tmp_string_clear "${TMP_FUNC_INPUT}"
					functionSegment=input
					return
				;;

				Output:*)
					tmp_string_clear "${TMP_FUNC_OUTPUT}"
					functionSegment=output
					return
				;;

				Return:*)
					tmp_string_clear "${TMP_FUNC_RETURN}"
					functionSegment=return
					return
				;;

				Example:*)
					tmp_string_clear "${TMP_FUNC_EXAMPLE}"
					functionSegment=example
					return
				;;
			esac
			k_log_info "Found function segment type: ${functionSegment} for '${line}'"

			case ${functionSegment} in
				description)
					parse_function_description "${line}"
				;;

				input)
					parse_function_input "${line}"
				;;

				output)
					parse_function_output "${line}"
				;;

				return)
					parse_function_return "${line}"
				;;

				example)
					parse_function_example "$(k_string_remove_start " " "${paddedLine}")"
				;;
			esac
		fi
	}

	parse_file() {
		local line

		add_header_property title "${file##*/}"

		while read -r line; do
			if [ ${headerMode} = true ]; then
				parse_header_line "${line}"
			else
				parse_body_line "${line}"
			fi
		done < "${file}"
	}


	while [ $# -gt 0 ]; do
		case "$1" in

			-h|--help)
				k_usage
				exit
			;;

			-V|--verbose)
				k_log_level ${KOALEPHANT_LOG_LEVEL_INFO} > /dev/null
				shift
			;;

			-D|--debug)
				k_log_level ${KOALEPHANT_LOG_LEVEL_DEBUG} > /dev/null
				shift
			;;

			-q|--quiet)
				k_log_level ${KOALEPHANT_LOG_LEVEL_ERR} > /dev/null
				shift
			;;

			-v|--version)
				k_version
				return
			;;

			-*)
				k_log_err "Unknown option: ${1}"
				k_usage
				return 1
			;;

			--)
				shift
				break
			;;

			*)
				break
			;;
		esac
	done

	if [ -z "${1:-}" ]; then
		k_log_err "No file specified"
		k_usage
		return 1
	fi

	file="$1"

	parse_file
	k_fs_temp_cleanup
}

k_shell_doc "$@"
