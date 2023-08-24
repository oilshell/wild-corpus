#@IgnoreInspection BashAddShebang
# GPG functionality (Koalephant Shell Script Library)
# Version: 2.0.0
# Copyright: 2014, Koalephant Co., Ltd
# Author: Stephen Reay <stephen@koalephant.com>, Koalephant Packaging Team <packages@koalephant.com>

# List GPG Public Key ID's
#
# Input:
# $1...n - query key id/name/email to query for, if set
#
# Output:
# the public key ID, if one or more keys are found
k_gpg_list_keys_public() {
	GPG_BIN --batch --no-tty --with-colons --list-public-keys -- "$@" | grep "^pub:" | cut -d ":" -f 5 2>/dev/null
}

# List GPG Secret Key ID's
#
# Input:
# $1...n - query key id/name/email to query for, if set
#
# Output:
# the secret key ID, if one or more keys are found
k_gpg_list_keys_secret() {
	GPG_BIN --batch --no-tty --with-colons --list-secret-keys -- "$@" | grep "^sec:" | cut -d ":" -f 5 2>/dev/null
}

# Generate a new GPG Key
#
# Input:
# $1 - the name for the key
# $2 - the email for the key
# $3 - optional comment for the key
# $4 - optional passphrase for the key. If not supplied, the key will not be protected with a passphrase!
#
# Output:
# the new Key ID
#
# Return:
# the exit code from gpg, usually 0 for success and 1 for error
k_gpg_create() {
	local name email comment passphraseLine gpgOut result

	name="${1}"
	email="${2}"
	comment="${3:-}"
	commentLine=""
	passphrase="${4:-}"
	passphraseLine=""

	if [ -n "${comment}" ]; then
		commentLine="Name-Comment: ${comment}"
	fi

	if [ -n "${passphrase}" ]; then
		passphraseLine="Passphrase: ${passphrase}"
	else
		passphraseLine="%no-protection"
	fi

	gpgOut="$(GPG_BIN --no-tty --batch --generate-key 2>&1 <<-EOT
		Key-Type: RSA
		Key-Length: 2048
		Name-Real: ${name}
		${commentLine}
		Name-Email: ${email}
		${passphraseLine}
		Expire-Date: 0
		%commit
EOT
)"

	result=$?

	if [ ${result} -eq 0 ]; then
		echo "${gpgOut}" | head -n 1 - | cut --delimiter " " --fields 3
	fi

	return ${result}
}

# Prompt for a new GPG Key Passphrase
#
# Input:
# $1 - the ID of the Key to set a passphrase for
#
# Return:
# the exit code from gpg, usually 0 for success and 1 for error
k_gpg_password_prompt() {
	local gpgKey

	gpgKey="${1}"

	GPG_BIN --quiet --edit-key -- "${gpgKey}" passwd save
}

# Export an ascii-armored GPG Key
#
# Input
# $1 - the ID of the Key to export
# $2 - the destination to export the key to. If a directory is given, a file named with the Key ID and a ".asc" extension will be created in the directory
#
# Return:
# the exit code from gpg, usually 0 for success and 1 for error
k_gpg_export_armored() {
	local key destination

	key="${1}"
	destination="${2}"

	if [ -d "${destination}" ]; then
		destination="${destination}/${key}.asc"
	fi

	GPG_BIN --armor --export -- "${key}" > "${destination}"
}

# Export a binary GPG key
#
# Input
# $1 - the ID of the Key to export
# $2 - the destination to export the key to. If a directory is given, a file named with the Key ID and a ".gpg" extension will be created in the directory
#
# Return:
# the exit code from gpg, usually 0 for success and 1 for error
k_gpg_export() {
	local key destination

	key="${1}"
	destination="${2}"

	if [ -d "${destination}" ]; then
		destination="${destination}/${key}.gpg"
	fi

	GPG_BIN --export -- "${key}" > "${destination}"
}

# Search for public keys on the configured keyserver(s)
#
# Input:
# $1 - the query term - usually a key ID, email or name.
#
# Output:
# The
k_gpg_search_keys() {
	local query="$1"

	GPG_BIN --no-tty --with-colons --batch --search-keys -- "${query}" 2>/dev/null
}

# Add a public key from the configured keyserver(s)
#
# Input:
# $1...n - the key IDs to add
#
# Output:
# The GPG message
k_gpg_receive_keys() {
	GPG_BIN --no-tty --batch --receive-keys -- "$@" 2>&1 | head -n -2 | cut -c 6-
}

# Check if a variable is in a valid key-id format
#
# Input:
# $1 - the variable to check
#
# Return:
# 0 if valid, 1 if not
k_gpg_keyid_valid() {
	local keyId="$1"
	if [ "${keyId%%0x*}" = "" ] && ([ ${#keyId} -eq 10 ] || [ ${#keyId} -eq 18 ]); then
		keyId="${keyId#0x}"
	fi
	([ ${#keyId} -eq 8 ] || [ ${#keyId} -eq 16 ]) && [ "${keyId}" = "$(printf "%s" "${keyId}" | tr -c -d 'ABCDEFabcdef0123456789')" ]
}
