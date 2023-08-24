#!/bin/sh -eu
# Create a manpage from the help/version output of an executable/script
# Version: 2.0.0
# Copyright: 2014, Koalephant Co., Ltd
# Author: Stephen Reay <stephen@koalephant.com>, Koalephant Packaging Team <packages@koalephant.com>

# Create a manpage from the help/version output of an executable/script
#
# Input:
# $1 - the executable or script
#
# Output:
# The rendered manpage, unless `--output` is given
k_help2man() {

	local KOALEPHANT_TOOL_VERSION="2.0.0"
	local KOALEPHANT_TOOL_DESCRIPTION="Create a manpage from the help/version output of a executable/script"
	local KOALEPHANT_TOOL_OPTIONS="$(cat <<-EOT
		Options:

		 -h, --help                    show this help
		 -H, --help-command command    set the help argument/option to use
		 -n, --name name               set the name to use for the tool
		 -N, --alt-name name           set an alternate name for the tool
		 -o, --output file             set the filename to output to (defaults to stdout)
		 -s, --section section         set the manpage section
		 -S, --source source           set the program source (i.e. a company/organisation or project/package name)
		 -v, --version                 show the version
		 -V, --version-command command set the version argument/option to use

EOT
	)"
	local KOALEPHANT_TOOL_ARGUMENTS="executable"

	. ./base.lib.sh
	. ./string.lib.sh
	. ./bool.lib.sh
	. ./fs.lib.sh

	local helpCommand="--help"
	local description=""
	local section="1"
	local source=""
	local versionCommand="--version"
	local output=/dev/stdout
	local changeDir=false
	local alternativeName=""

	while [ $# -gt 0 ]; do
		case "$1" in

			-h|--help)
				k_usage
				exit
			;;

			-c|--cd)
				changeDir=true
				shift
			;;

			-H|--help-command)
				helpCommand="$(k_option_requires_arg "$@")"
				shift 2
			;;

			-d|--description)
				description="$(k_option_requires_arg "$@")"
				shift 2
			;;

			-N|--alt-name)
				alternativeName="$(k_option_requires_arg "$@")"
				shift 2
			;;

			-o|--output)
				output="$2"
				shift 2
			;;

			-s|--section)
				section="$(k_option_requires_arg "$@")"
				shift 2
			;;

			-S|--source)
				source="$(k_option_requires_arg "$@")"
				shift 2
			;;

			-v|--version)
				k_version
				exit
			;;

			-V|--version-command)
				versionCommand="$(k_option_requires_arg "$@")"
				shift 2
			;;

			-*)
				echo "Unknown option: ${1}" >&2
				k_usage
				exit 1
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

	local executable="$(k_fs_resolve "${1}")"
	local executableName="$(k_fs_basename "${executable}" .sh)"
	local dir="$(k_fs_dirname "${executable}")"
	local includeFile="${dir}/${executableName}.${section}.man"
	local tmpIncludeFile="$(k_fs_temp_file)"

	if [ -z "${executable}" ]; then
		echo "Executable (${executable}) not provided";
		k_usage;
		exit 1
	elif [ ! -f "${executable}" ] || [ ! -x "${executable}" ]; then
		echo "Executable (${executable}) not an executable file";
		k_usage;
		exit 1
	fi

	if [ ${changeDir} = true ]; then
		# Adjust output if file
		cd "${dir}"
		executable="./$(k_fs_basename "${executable}")"
	fi

	if [ -z "${description}" ]; then
		description="$(${executable} ${helpCommand} | sed -E -n -e '/^\s*(Usage|\s*or):/!p' | head -n 1)"
	fi

	printf "[NAME]\n%s - %s\n\n" "$(k_string_join ", " ${executableName} ${alternativeName})" "${description}" > "${tmpIncludeFile}"
	if [ -f "${includeFile}" ]; then
		cat "${includeFile}" >> "${tmpIncludeFile}"
	fi

	help2man \
	 		--section "${section}" \
			--no-info \
			--include "${tmpIncludeFile}" \
			--help-option "${helpCommand}" \
			--version-option "${versionCommand}" \
			--source "${source}" "${executable}" > ${output}

}

k_help2man "$@"
