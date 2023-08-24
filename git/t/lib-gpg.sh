#!/bin/sh

gpg_version=$(gpg --version 2>&1)
if test $? != 127
then
	# As said here: http://www.gnupg.org/documentation/faqs.html#q6.19
	# the gpg version 1.0.6 didn't parse trust packets correctly, so for
	# that version, creation of signed tags using the generated key fails.
	case "$gpg_version" in
	'gpg (GnuPG) 1.0.6'*)
		say "Your version of gpg (1.0.6) is too buggy for testing"
		;;
	*)
		# Available key info:
		# * Type DSA and Elgamal, size 2048 bits, no expiration date,
		#   name and email: C O Mitter <committer@example.com>
		# * Type RSA, size 2048 bits, no expiration date,
		#   name and email: Eris Discordia <discord@example.net>
		# No password given, to enable non-interactive operation.
		# To generate new key:
		#	gpg --homedir /tmp/gpghome --gen-key
		# To write armored exported key to keyring:
		#	gpg --homedir /tmp/gpghome --export-secret-keys \
		#		--armor 0xDEADBEEF >> lib-gpg/keyring.gpg
		#	gpg --homedir /tmp/gpghome --export \
		#		--armor 0xDEADBEEF >> lib-gpg/keyring.gpg
		# To export ownertrust:
		#	gpg --homedir /tmp/gpghome --export-ownertrust \
		#		> lib-gpg/ownertrust
		mkdir ./gpghome &&
		chmod 0700 ./gpghome &&
		GNUPGHOME="$(pwd)/gpghome" &&
		export GNUPGHOME &&
		gpg --homedir "${GNUPGHOME}" 2>/dev/null --import \
			"$TEST_DIRECTORY"/lib-gpg/keyring.gpg &&
		gpg --homedir "${GNUPGHOME}" 2>/dev/null --import-ownertrust \
			"$TEST_DIRECTORY"/lib-gpg/ownertrust &&
		gpg --homedir "${GNUPGHOME}" </dev/null >/dev/null 2>&1 \
			--sign -u committer@example.com &&
		test_set_prereq GPG
		;;
	esac
fi

if test_have_prereq GPG &&
    echo | gpg --homedir "${GNUPGHOME}" -b --rfc1991 >/dev/null 2>&1
then
	test_set_prereq RFC1991
fi

sanitize_pgp() {
	perl -ne '
		/^-----END PGP/ and $in_pgp = 0;
		print unless $in_pgp;
		/^-----BEGIN PGP/ and $in_pgp = 1;
	'
}
