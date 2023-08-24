#@IgnoreInspection BashAddShebang
# Filesystem functionality (Koalephant Shell Script Library)
# Version: 2.0.0
# Copyright: 2017, Koalephant Co., Ltd
# Author: Stephen Reay <stephen@koalephant.com>, Koalephant Packaging Team <packages@koalephant.com>

# Resolve a given filesystem path to an absolute path
#
# Input:
# $1 - the path to resolve
#
# Output:
# the resolved path
k_fs_resolve() {
	local path="${1%/}"
	local dir=""
	local base=""
	if [ -d "${path}" ]; then
		dir="${path}"
	else
		dir="$(k_fs_dirname "${path}")"
		base="/$(k_fs_basename "${path}")"
	fi

	if [ -z "${dir}" ]; then
		dir="."
	fi

	printf "%s%s" "$(cd "${dir}" && pwd -P)" "${base}"
}

# Get the base name of a filesystem path, optionally with an extension removed
#
# Input:
# $1 - the path to get the basename of
# $2 - the extension to remove if found
#
# Output:
# the base name of the given path
k_fs_basename() {
	local path="${1%/}"
	local extension="${2:-}"

	path="${path##*/}"

	if [ -n "${extension}" ]; then
		path="${path%$extension}"
	fi

	printf "%s" "${path:-/}"
}

# Get the parent directory path of a filesystem path
#
# Input:
# $1 - the path to get the parent directory path of
#
# Output:
# the parent directory name of the given path
k_fs_dirname() {
	local path="${1%/}"
	local dirPath="${path%/*}"

	if [ -n "${path}" ] && [ "${path}" = "${dirPath}" ]; then
		dirPath="."
	fi

	printf "%s" "${dirPath:-/}"
}

# Get a temp directory
#
# Output:
# the temp directory path
k_fs_temp_dir() {
	local tmpDir="$(mktemp -d)"

	k_log_debug "Created temporary directory: '${tmpDir}'"

	printf "%s\n" "${tmpDir}" >> "$(k_fs_predictable_file k-fs-temp-files)"

	printf "%s" "${tmpDir}"
}

# Get a temp file
#
# Output:
# the temp file path
k_fs_temp_file() {
	local tmpFile="$(mktemp)"

	k_log_debug "Created temporary file: '${tmpFile}'"

	printf "%s\n" "${tmpFile}" >> "$(k_fs_predictable_file k-fs-temp-files)"

	printf "%s" "${tmpFile}"
}

# Get a 'predictable' temporary directory
# The directory path is generated using constants for this process, so they can be retrieved within a trap callback
#
# Input:
# $1 - the basename for the directory. If not specified, the output of (#k_tool_name) is used
#
# Output:
# the temporary directory name
k_fs_predictable_dir() {
	local tmpDir="$(k_fs_dirname "$(mktemp -u)")/${1:-$(k_tool_name)}.$$"
	mkdir -p "${tmpDir}"

	k_log_debug "Created predictable temporary directory: '${tmpDir}'"

	printf "%s\n" "${tmpDir}" >> "$(k_fs_predictable_file k-fs-temp-files)"

	printf "%s" "${tmpDir}"
}

# Get a 'predictable' temporary file
# The file path is generated using constants for this process, so they can be retrieved within a trap callback
#
# Input:
# $1 - the basename for the file. If not specified, the output of (#k_tool_name) is used
#
# Output:
# the temporary file name
k_fs_predictable_file() {
	local name="${1:-$(k_tool_name)}"
	local tmpFile="$(k_fs_dirname "$(mktemp -u)")/${name}.$$"


	k_log_debug "Created predictable temporary file: '${tmpFile}'"

	if [ ! "${name}" = "k-fs-temp-files" ]; then
		printf "%s\n" "${tmpFile}" >> "$(k_fs_predictable_file k-fs-temp-files)"
	fi

	printf "%s" "${tmpFile}"
}

# Cleanup temp files and directories
k_fs_temp_cleanup() {
	local tempFilesFile="$(k_fs_predictable_file k-fs-temp-files)"
	k_log_info "Cleaning up temp files"
	while IFS= read -r file; do
		k_log_debug "Removing '${file}'"
		rm -rf "${file}"
	done < "${tempFilesFile}"

	k_log_debug "Removing '${tempFilesFile}'"
	rm -f "${tempFilesFile}"

}
