set -e;

# maintain a cached copy of coreos pxe image

if [ -z "${IMG_URL}" -o -z "${ITMP}" -o -z "${V}" ]; then
	exit 1
fi

if [ ${V} -eq 3 ]; then
	set -x
fi

# coreos gpg signing key
# pub   4096R/93D2DCB4 2013-09-06
# uid       [ unknown] CoreOS Buildbot (Offical Builds) <buildbot@coreos.com>
# sub   4096R/74E7E361 2013-09-06 [expired: 2014-09-06]
# sub   4096R/E5676EFC 2014-09-08 [expired: 2015-09-08]
# sub   4096R/1CB5FA26 2015-08-31 [expires: 2017-08-30]
# sub   4096R/B58844F1 2015-11-20 [revoked: 2016-05-16]
# sub   4096R/2E16137F 2016-05-16 [expires: 2017-05-16]
# sub   4096R/EF4B4ED9 2017-05-22 [expires: 2018-06-01]
GPG_LONG_ID="50E0885593D2DCB4"
GPG_KEY="-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2

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
tNPsShDTwMfzQ7k8ah9PXA==
=NfcE
-----END PGP PUBLIC KEY BLOCK-----
"

# prints passed flags if verbosity level is lower; to be used inside
# output capture (backticks or $())
function be_quiet() {
	local verbosity	#verbosity level
	local flags	#silencing flags to use

	verbosity=$1
	flags=$2

	if [ $verbosity -lt 3 ]; then
		printf '%s\n' "${flags}"
	fi
}

# gpg verify a file using the provided key
function gpg_verify() {
	local file	#file to verify
	local sigfile	#signature file (assumed to be suffixed form of file to verify)
	local key	#signing key
	local keyid	#signing key signature
	local verbosity	#verbosity level

	local quiet
	local gpghome

	file=$1
	sigfile=$2
	key=$3
	keyid=$4
	verbosity=$5

	quiet=$(be_quiet $verbosity '--quiet --no-verbose')
	gpghome=$(mktemp -d)
	trap "{ rm -rf '${gpghome}'; }" RETURN EXIT
	if ! gpg --homedir="${gpghome}" --batch --quiet --import <<<"${key}"; then
		return 1
	fi
	if ! gpg --homedir="${gpghome}" --batch ${quiet} --trusted-key "${keyid}" --verify "${sigfile}" "${file}"; then
		return 1
	fi
	return 0
}

function do_wget() {
	local out	#output file
	local url	#url of a file to be downloaded
	local verbosity	#verbosity level

	local quiet
	local short_out

	out=$1
	url=$2
	verbosity=$3

	quiet=$(be_quiet $verbosity '--quiet')
	if [ "${quiet}" ]; then
		# strip the working directory from output path, so we get
		# something like build-rkt/tmp/coreos-common/pxe.img
		# instead of /home/foo/projects/rkt/rkt/build-rkt/...
		short_out="${out#${PWD}/}"
		printf '  %-12s %s\n' 'WGET' "${url} => ${short_out}"
	fi
	wget ${quiet} --tries=20 --output-document="${out}" "${url}" # the wget default for retries is 20 times.
}

function cat_to_stderr_if_verbose() {
	local file
	local verbosity

	file=$1
	verbosity=$2

	if [ -z $(be_quiet $verbosity 'empty-if-verbose') ]; then
		cat "${file}" >&2
	fi
}

# maintain an gpg-verified url cache, assumes signature available @ $url.sig
function cache_url() {
	local cache	#verified cache, will be downloaded from the url if bad or missing
	local url	#url of the file to be downloaded
	local key	#key used for verification
	local keyid	#id of a key used for verification
	local verbosity	#verbosity level

	local urlhash
	local sigfile
	local sigurl
	local gpgout

	cache=$1
	url=$2
	key=$3
	keyid=$4
	verbosity=$5

	urlhash=$(echo -n "${url}" | md5sum)
	sigfile="${cache}.${urlhash%% *}.sig"
	sigurl="${url}.sig"

	gpgout=$(mktemp)
	trap "{ rm -f '${gpgout}'; }" RETURN EXIT
	# verify the cached copy if it exists
	if ! gpg_verify "${cache}" "${sigfile}" "${key}" "${keyid}" "${verbosity}" 2>"${gpgout}"; then
		# refresh the cache on failure, and verify it again
		cat_to_stderr_if_verbose "${gpgout}" "${verbosity}"
		do_wget "${cache}" "${url}" "${verbosity}"
		do_wget "${sigfile}" "${sigurl}" "${verbosity}"
		if ! gpg_verify "${cache}" "${sigfile}" "${key}" "${keyid}" "${verbosity}" 2>"${gpgout}"; then
			# print an error if verification failed
			cat "${gpgout}" >&2
			return 1
		fi
		cat_to_stderr_if_verbose "${gpgout}" "${verbosity}"
	else
		cat_to_stderr_if_verbose "${gpgout}" "${verbosity}"
	fi

	# file $cache exists and can be trusted
	touch "${cache}"
}

# cache pxe image
cache_url "${ITMP}/pxe.img" "${IMG_URL}" "${GPG_KEY}" "${GPG_LONG_ID}" "${V}"
