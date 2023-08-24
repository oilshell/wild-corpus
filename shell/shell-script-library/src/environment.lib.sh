#@IgnoreInspection BashAddShebang
# Environment handling functionality (Koalephant Shell Script Library)
# Version: 2.0.0
# Copyright: 2014, Koalephant Co., Ltd
# Author: Stephen Reay <stephen@koalephant.com>, Koalephant Packaging Team <packages@koalephant.com>

# Prefix to use when setting environment variables
KOALEPHANT_ENVIRONMENT_PREFIX=""

# Make sure a name is safe for use as a variable name
#
# Input:
# $1 - the name to make safe
#
# Output:
# The save variable name
k_env_safename() {
	echo "${KOALEPHANT_ENVIRONMENT_PREFIX}${1}"  | tr -cd '[:alnum:]_'
}

# Set a local variable
#
# Input:
# $1 - the name of the variable to set
# $2 - the value to set
k_env_set() {
	local name value msg tmpN existing nsName

	if [ $# -lt 2 ]; then
		echo "Not enough arguments passed to k_env_set: '$@'" >&2
		return 1
	fi

	name=$(k_env_safename "${1}")
	value="${2}"

	k_debug 2 "Setting '${name}' environment variable to '${value}'"

	export "${name}=${value}"
}

# Unset one or more environment variables
#
# Input:
# $1...n variables to unset from the environment
k_env_unset() {
	local name

	for name in "$@"; do
		k_debug 2 "Unsetting '${name}' environment variable"
		unset "$(k_env_safename "${name}")"
	done
}

# Export one or more environment variables
#
# Input:
# $1...n variables to export for child processes
k_env_export() {
	local name

	for name in "$@"; do
		echo "export \"${name}=$(eval "echo \${${name}}")\""
	done
}

# Un-Export one or more environment variables
#
# Input:
# $1...n - variables to un-export
k_env_unexport() {
	echo "unset $@"
}

# Import environment variables from the GECOS field
#
# Input:
# $1 the user to import from. Defaults to the current logged in user.
k_env_import_gecos() {
	local userName passwdEntry gecos i name value

	k_debug 2 "Importing Environment Variables from GECOS field"

	# If no argument is provided, use $USER
	userName="${1:-${USER}}"
	passwdEntry=$(getent passwd "${userName}")

	if [ "$?" != "0" ]; then
		return $?
	fi
	gecos=$(echo "${passwdEntry}" | cut -d ":" -f 5)

	i=1
	for name in NAME ROOM TELEPHONE_WORK TELEPHONE_HOME EMAIL; do
		k_env_set "${name}" "$(echo "${gecos}" | cut -d "," -f "${i}")"

		if ! k_string_contains "${name}" "${KOALEPHANT_ENV_NS_GECOS}"; then
			export KOALEPHANT_ENV_NS_GECOS="${KOALEPHANT_ENV_NS_GECOS} ${name}"
		fi

		i=$((${i} + 1))
	done
}

# Export environment variables previously imported with (#k_env_import_gecos)
k_env_export_gecos() {
	k_env_export ${KOALEPHANT_ENV_NS_GECOS}
}

# Unset environment variables previously imported with {k_env_import_gecos}
k_env_unset_gecos() {
	k_env_unset ${KOALEPHANT_ENV_NS_GECOS} KOALEPHANT_ENV_NS_GECOS
}


# Import environment variables from an apache config file
#
# Input:
# $1 - the apache config file to set environment variables from
k_env_import_apache() {
	local lines line name value

	local IFS="$(printf '\n ')" && IFS="${IFS% }"
	local file="${1}"
	local setMode="${2:-true}"

	if [ ! -f "${file}" ]; then
		echo "Invalid file supplied: '${file}'" >&2
		exit 1
	fi

	k_debug 2 "Importing Environment Variables from Apache Config: '${file}'"

	lines=$(grep -o -E "SetEnv[[:space:]].*" "${file}")

	if [ $? != 0 ]; then
		return $?
	fi

	for line in ${lines}; do
		name=$(echo "${line}" | cut -d " " -f 2)
		value=$(echo "${line}" | cut -d " " -f 3- | perl -e 's/^"//g; s/(?<!\\)"$//g; s/"/\"/g' -p)

		k_env_set "${name}" "${value}"

		if ! k_string_contains "${name}" "${KOALEPHANT_ENV_NS_APACHE}"; then
			export KOALEPHANT_ENV_NS_APACHE="${KOALEPHANT_ENV_NS_APACHE} ${name}"
		fi
	done

}

# Export environment variables previously imported with (#k_env_import_apache)
k_env_export_apache() {
	k_env_export ${KOALEPHANT_ENV_NS_APACHE} KOALEPHANT_ENV_NS_APACHE
}

# Unset environment variables previously imported with @link k_env_import_apache @/link
k_env_unset_apache() {
	k_env_unset ${KOALEPHANT_ENV_NS_APACHE} KOALEPHANT_ENV_NS_APACHE
}

# Un-Export environment variables previously exported with @link k_env_import_apache @/link
k_env_unexport_apache() {
	k_env_unexport ${KOALEPHANT_ENV_NS_APACHE} KOALEPHANT_ENV_NS_APACHE
}

# Import environment variables from an LDAP object
# @discussion import the specified attributes as environment variables
# @param filter the mode to operate in, set or unset
# @param attr..n the attributes to fetch
k_env_import_ldap() {
	local filter i line name origName longName value result

	filter="${1}"
	shift

	if [ -z "${filter}" ]; then
		echo "No filter supplied" >&2
		exit 1
	fi

	k_debug 2 "Importing Environment Variables from LDAP with Filter: '${filter}'"

	# attribute renaming maps:
	if [ -d "${KOALEPHANT_LIB_PATH}/ldap-attr-maps" ]; then
		for i in "${KOALEPHANT_LIB_PATH}/ldap-attr-maps/"*.attrs; do
			if [ -r "${i}" ]; then
				for line in $(grep --only-matching '^\(ATTR_[a-zA-Z0-9\-]\+\)=\([a-zA-Z0-9\-]\+\)$' "${i}"); do
					eval "local ${line}"
				done
			fi
		done
	fi

	result=$(ldapsearch -x -LLL -o ldif-wrap=no "(${filter})" "$@")

	for line in ${result}; do
		name=$(echo "${line}" | grep --only-matching "^[^:]*")
		origName="${name}"
		longName=$(eval echo "\$ATTR_${name}")
		if [ ! -z "${longName}" ]; then
			name="${longName}"
		fi

		name=$(k_string_upper $(k_string_split_camelcase "${name}" "_"))

		value=$(echo "${line}" | cut -b "$((${#origName} + 3))-")

		k_env_set "${name}" "${value}" "LDAP"

		if ! k_string_contains "${name}" "${KOALEPHANT_ENV_NS_LDAP}"; then
			export KOALEPHANT_ENV_NS_LDAP="${KOALEPHANT_ENV_NS_LDAP} ${name}"
		fi

	done
}

# Export environment variables previously imported with @link k_env_import_ldap @/link
k_env_export_ldap() {
	k_env_export ${KOALEPHANT_ENV_NS_LDAP}
}

# Unset environment variables previously imported with @link k_env_import_ldap @/link
k_env_unset_ldap() {
	k_env_unset ${KOALEPHANT_ENV_NS_LDAP} KOALEPHANT_ENV_NS_LDAP
}
