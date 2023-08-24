#!/bin/sh -eu
# Process shell source (.) statements into absolute references or inline the script
# Version: 2.0.0
# Copyright: 2017, Koalephant Co., Ltd
# Author: Stephen Reay <stephen@koalephant.com>, Koalephant Packaging Team <packages@koalephant.com>

# Process shell source (.) statements into absolute references or inline the script
k_script_build() {

	local KOALEPHANT_TOOL_VERSION="1.0.0"
	local KOALEPHANT_TOOL_DESCRIPTION="Process shell source (.) statements into absolute references or inline the script"
	local KOALEPHANT_TOOL_OPTIONS="$(cat <<-EOT
		Options:

		 -c, --cd                           change to the input file directory before building
		 -f, --file file                    the source to read. If not specified, defaults to stdin
		 -o, --output file                  the file to write to. If not specified, defaults to stdout
		 -d, --define var=val               define simple replacements to be performed while processing e.g. LIB_PATH=/foo
		 -i, --inline, --static path        dir or file path to explicitly inline. Can be specified multiple times
		 -l, --link, --dynamic path=abs     dir or file path to explicitly link to. Can be specified multiple times
		 -r, --report                       process input and report all discovered inclusions
		 -x, --executable                   mark the resulting file (if not stdout) executable
		 -h, --help                         show this help
		 -v, --version                      show the version
		 -V, --verbose                      show verbose output
		 -D, --debug                        show debug output
		 -q, --quiet                        suppress all output except errors

EOT
	)"
	local FIND_SOURCE_LINES="s/^\s*\. (.*)/K_SCRIPT_BUILD_REPORT\\1/p"
	readonly FIND_SOURCE_LINES

	local FIX_NEWLINES='$a\\'
	readonly FIX_NEWLINES

	local infile=/dev/stdin
	local outfile=/dev/stdout

	local executable=false

	local report=false
	local changeDir=false
	local changeDirPath=""

	local sourcePaths=""
	local definitions=""

	local newline="$(printf '\n ')"
	newline="${newline% }"

	. ./shell-script-library.lib.sh

	k_log_level ${KOALEPHANT_LOG_LEVEL_NOTICE} > /dev/null

	add_source_path() {
		local type="$1"
		local source="$2"
		local value="${3:-}"
		local sep=""
		if [ -n "${sourcePaths}" ]; then
			sep="\n"
		fi

		sourcePaths="$(printf "%s${sep}%s#%s#%s" "${sourcePaths}" "${type}" "${source}" "${value}")"
	}

	add_dynamic_mapping() {
		local find="$1"
		local target="$2"

		k_log_info "Adding dynamic mapping for '${find}' => '${target}'"
		add_source_path dynamic "${find}" "${target}"
	}

	add_static_path() {
		local path="$1"
		k_log_info "Adding static path for '${path}'"
		add_source_path static "${path}"
	}
	
	add_definition() {
		local definition="$1"
		local value="$2"
		local sep=""
		if [ -n "${definitions}" ]; then
			sep="\n"
		fi

		k_log_info "Adding definition for '${definition}' with value '${value}'"

		definitions="$(printf "%s${sep}%s %s" "${definitions}" "$definition" "${value}")"
	}

	get_definition_pattern() {
		echo "${definitions}" | while IFS=" " read -r key value; do
			if [ -z "${key}" ]; then
				continue
			fi
			k_log_debug "Using definition: '${key}' = '${value}'"
			printf "s#([^A-Za-z0-9_])%s([^A-Za-z0-9_])#\\\\1%s\\\\2#g; " "${key}" "${value}"
		done
	}

	get_include_pattern() {
		echo "${sourcePaths}" | while IFS="#" read -r type source value; do
			case "${type}" in
				dynamic)
					printf "s#%s#%s#g; " "^(\s*\.\s+)([\'\"]?)($(escape_sed_pattern "${source}"))(.*\2\s*)\$" "\1\2$(escape_sed_replacement "${value}")\4"
				;;

				static)
					printf "s#%s#%s#g; " "^(\s*)\.\s+([\'\"]?)($(glob_to_sed ${source}))\2\s*$" "K_SCRIPT_BUILD_INCLUDE\1\3"
				;;

			esac
		done
	}

	glob_to_sed() {
		local pattern=""
		local sep="|"
		k_log_debug "Converting glob pattern to sed: '$@'"
		for file in "$@"; do
			k_log_debug "Checking file exists: '${file}'"
			if [ -e "${file}" ]; then
				pattern="${pattern}$(escape_sed_pattern "${file}")${sep}"
			fi
		done

		printf "%s" "${pattern%${sep}}"
	}

	escape_sed_pattern() {
		echo "${1}" | sed -e 's/[]\/$*.^\|[()?+{}]/\\&/g'
	}

	escape_sed_replacement() {
		local delimiter="${2:-/}"

		if [ ${#delimiter} -ne 1 ]; then
			k_log_alert "Error, pattern delimiter must be exactly one character: ${delimiter}"
			return 2
		fi

		echo "${1}" | sed -e "s/[\\${delimiter}\&]/\\\\&/g"
	}


	process_stream() {
		local pattern="$1"
		local parentPrefix="${2:-}"
		if [ $# -ge 2 ]; then
			shift 2
		else
			shift
		fi
		local sedOpts="$*"

		local defPattern="$(get_definition_pattern)"

		k_log_debug "Processing stream using pattern: '${pattern}', definition pattern: '${defPattern}'"

		sed -E ${sedOpts} -e "${FIX_NEWLINES}" -e "${defPattern}" -e "s/^/${parentPrefix}/g" -e "${pattern}" | while IFS= read -r line; do
			local prefix="${parentPrefix}"
			local includeFile=""

			case "${line}" in
				(K_SCRIPT_BUILD_INCLUDE*)
					k_log_debug "Processing 'include' line: '${line}"
					line="$(k_string_remove_start "K_SCRIPT_BUILD_INCLUDE" "${line}")"
					trimmed="$(k_string_trim "${line}")"
					prefix="${prefix}$(k_string_remove_end "${trimmed}" "${line}")"
					includeFile="${trimmed}"
				;;

				(K_SCRIPT_BUILD_REPORT*)
					k_log_debug "Processing 'report' line: '${line}"
					line="$(k_string_remove_start "K_SCRIPT_BUILD_REPORT" "${line}")"
					printf "%s\n" "${line}"
				;;
			esac

			if [ -n "${includeFile}" ] && [ -f "${includeFile}" ]; then
				k_log_debug "Including file: '${includeFile}'"
				printf "${prefix}#K_SCRIPT_BUILD: include(%s)\n" "${includeFile}"
				process_stream "${pattern}" "${prefix}" ${sedOpts} < "${includeFile}"
			else
				k_log_debug "Regular line: '${line}'"
				printf "%s\n" "${line}"
			fi
		done
	}

	handle_changedir() {
		if [ ${changeDir} = true ]; then
			if [ -z "${changeDirPath}" ]; then
				if [ -f "${infile}" ]; then
					changeDirPath="$(k_fs_dirname "${infile}")"
				else
					k_log_err "No directory given to -c/--cd and no -f/--file specified"
					return 2
				fi
			fi


			if [ -f "${infile}" ]; then
				infile="$(k_fs_resolve "${infile}")"
			fi

			if [ -n "${outfile}" ]; then
				outfile="$(k_fs_resolve "${outfile}")"
			fi

			cd "${changeDirPath}"
		fi
	}

	handle_executable() {
		if [ ${executable} = true ]; then
			if [ -f "${outfile}" ]; then
				chmod +x "${outfile}"
			else
				k_log_err "Cannot set executable bit when output is stdout"
				return 2
			fi
		fi
	}

	local tmpVal
	while [ $# -gt 0 ]; do
		case "$1" in

			-h|--help)
				k_usage
				exit
			;;

			-c|--cd)
				changeDir=true
				changeDirPath="$(k_option_optional_arg "$@")"
				if [ -n "${changeDirPath}" ]; then
					shift
				fi
				shift

			;;

			-f|--file)
				infile="$(k_option_requires_arg "$@")"
				shift 2
			;;

			-d|--define)
				tmpVal="$(k_option_requires_arg "$@")"
				add_definition "$(echo "${tmpVal}" | cut -d = -f 1)" "$(echo "${tmpVal}" | cut -d = -f 2)"
				shift 2
			;;

			-o|--output)
				outfile="$(k_option_requires_arg "$@")"
				shift 2
			;;

			-i|--inline|--static)
				tmpVal="$(k_option_optional_arg "$@")"
				if [ -n "${tmpVal}" ]; then
					add_static_path "${tmpVal}"
					shift 2
				else
					add_static_path "./*"
					shift
				fi
			;;

			-l|--link|--dynamic)
				tmpVal="$(k_option_requires_arg "$@")"
				add_dynamic_mapping "$(echo "${tmpVal}" | cut -d = -f 1)" "$(echo "${tmpVal}" | cut -d = -f 2)"
				shift 2
			;;

			-r|--report)
				report=true
				shift
			;;

			-x|--exec|--executable)
				executable=true
				shift
			;;

			-v|--version)
				k_version
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

			--)
				shift
				break
			;;

			-*)
				echo "Unknown option: ${1}" >&2
				k_usage
				exit 1
			;;

			*)
				break
			;;
		esac
	done

	handle_changedir

	if [ ${report} = true ]; then
		process_stream "${FIND_SOURCE_LINES}" "" -n < "${infile}" > "${outfile}"
		return
	fi

	process_stream "$(get_include_pattern)" < "${infile}" > "${outfile}"

	handle_executable
}

k_script_build "$@"
