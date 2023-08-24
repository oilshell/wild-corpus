#!/bin/sh
#
# Copyright (c) 2007 Andy Parkins
#

test_description='for-each-ref test'

. ./test-lib.sh
. "$TEST_DIRECTORY"/lib-gpg.sh

# Mon Jul 3 23:18:43 2006 +0000
datestamp=1151968723
setdate_and_increment () {
    GIT_COMMITTER_DATE="$datestamp +0200"
    datestamp=$(expr "$datestamp" + 1)
    GIT_AUTHOR_DATE="$datestamp +0200"
    datestamp=$(expr "$datestamp" + 1)
    export GIT_COMMITTER_DATE GIT_AUTHOR_DATE
}

test_expect_success setup '
	setdate_and_increment &&
	echo "Using $datestamp" > one &&
	git add one &&
	git commit -m "Initial" &&
	setdate_and_increment &&
	git tag -a -m "Tagging at $datestamp" testtag &&
	git update-ref refs/remotes/origin/master master &&
	git remote add origin nowhere &&
	git config branch.master.remote origin &&
	git config branch.master.merge refs/heads/master &&
	git remote add myfork elsewhere &&
	git config remote.pushdefault myfork &&
	git config push.default current
'

test_atom() {
	case "$1" in
		head) ref=refs/heads/master ;;
		 tag) ref=refs/tags/testtag ;;
		   *) ref=$1 ;;
	esac
	printf '%s\n' "$3" >expected
	test_expect_${4:-success} $PREREQ "basic atom: $1 $2" "
		git for-each-ref --format='%($2)' $ref >actual &&
		sanitize_pgp <actual >actual.clean &&
		test_cmp expected actual.clean
	"
}

test_atom head refname refs/heads/master
test_atom head refname:short master
test_atom head refname:strip=1 heads/master
test_atom head refname:strip=2 master
test_atom head upstream refs/remotes/origin/master
test_atom head upstream:short origin/master
test_atom head push refs/remotes/myfork/master
test_atom head push:short myfork/master
test_atom head objecttype commit
test_atom head objectsize 171
test_atom head objectname $(git rev-parse refs/heads/master)
test_atom head objectname:short $(git rev-parse --short refs/heads/master)
test_atom head tree $(git rev-parse refs/heads/master^{tree})
test_atom head parent ''
test_atom head numparent 0
test_atom head object ''
test_atom head type ''
test_atom head '*objectname' ''
test_atom head '*objecttype' ''
test_atom head author 'A U Thor <author@example.com> 1151968724 +0200'
test_atom head authorname 'A U Thor'
test_atom head authoremail '<author@example.com>'
test_atom head authordate 'Tue Jul 4 01:18:44 2006 +0200'
test_atom head committer 'C O Mitter <committer@example.com> 1151968723 +0200'
test_atom head committername 'C O Mitter'
test_atom head committeremail '<committer@example.com>'
test_atom head committerdate 'Tue Jul 4 01:18:43 2006 +0200'
test_atom head tag ''
test_atom head tagger ''
test_atom head taggername ''
test_atom head taggeremail ''
test_atom head taggerdate ''
test_atom head creator 'C O Mitter <committer@example.com> 1151968723 +0200'
test_atom head creatordate 'Tue Jul 4 01:18:43 2006 +0200'
test_atom head subject 'Initial'
test_atom head contents:subject 'Initial'
test_atom head body ''
test_atom head contents:body ''
test_atom head contents:signature ''
test_atom head contents 'Initial
'
test_atom head HEAD '*'

test_atom tag refname refs/tags/testtag
test_atom tag refname:short testtag
test_atom tag upstream ''
test_atom tag push ''
test_atom tag objecttype tag
test_atom tag objectsize 154
test_atom tag objectname $(git rev-parse refs/tags/testtag)
test_atom tag objectname:short $(git rev-parse --short refs/tags/testtag)
test_atom tag tree ''
test_atom tag parent ''
test_atom tag numparent ''
test_atom tag object $(git rev-parse refs/tags/testtag^0)
test_atom tag type 'commit'
test_atom tag '*objectname' 'ea122842f48be4afb2d1fc6a4b96c05885ab7463'
test_atom tag '*objecttype' 'commit'
test_atom tag author ''
test_atom tag authorname ''
test_atom tag authoremail ''
test_atom tag authordate ''
test_atom tag committer ''
test_atom tag committername ''
test_atom tag committeremail ''
test_atom tag committerdate ''
test_atom tag tag 'testtag'
test_atom tag tagger 'C O Mitter <committer@example.com> 1151968725 +0200'
test_atom tag taggername 'C O Mitter'
test_atom tag taggeremail '<committer@example.com>'
test_atom tag taggerdate 'Tue Jul 4 01:18:45 2006 +0200'
test_atom tag creator 'C O Mitter <committer@example.com> 1151968725 +0200'
test_atom tag creatordate 'Tue Jul 4 01:18:45 2006 +0200'
test_atom tag subject 'Tagging at 1151968727'
test_atom tag contents:subject 'Tagging at 1151968727'
test_atom tag body ''
test_atom tag contents:body ''
test_atom tag contents:signature ''
test_atom tag contents 'Tagging at 1151968727
'
test_atom tag HEAD ' '

test_expect_success 'Check invalid atoms names are errors' '
	test_must_fail git for-each-ref --format="%(INVALID)" refs/heads
'

test_expect_success 'arguments to :strip must be positive integers' '
	test_must_fail git for-each-ref --format="%(refname:strip=0)" &&
	test_must_fail git for-each-ref --format="%(refname:strip=-1)" &&
	test_must_fail git for-each-ref --format="%(refname:strip=foo)"
'

test_expect_success 'stripping refnames too far gives an error' '
	test_must_fail git for-each-ref --format="%(refname:strip=3)"
'

test_expect_success 'Check format specifiers are ignored in naming date atoms' '
	git for-each-ref --format="%(authordate)" refs/heads &&
	git for-each-ref --format="%(authordate:default) %(authordate)" refs/heads &&
	git for-each-ref --format="%(authordate) %(authordate:default)" refs/heads &&
	git for-each-ref --format="%(authordate:default) %(authordate:default)" refs/heads
'

test_expect_success 'Check valid format specifiers for date fields' '
	git for-each-ref --format="%(authordate:default)" refs/heads &&
	git for-each-ref --format="%(authordate:relative)" refs/heads &&
	git for-each-ref --format="%(authordate:short)" refs/heads &&
	git for-each-ref --format="%(authordate:local)" refs/heads &&
	git for-each-ref --format="%(authordate:iso8601)" refs/heads &&
	git for-each-ref --format="%(authordate:rfc2822)" refs/heads
'

test_expect_success 'Check invalid format specifiers are errors' '
	test_must_fail git for-each-ref --format="%(authordate:INVALID)" refs/heads
'

test_date () {
	f=$1 &&
	committer_date=$2 &&
	author_date=$3 &&
	tagger_date=$4 &&
	cat >expected <<-EOF &&
	'refs/heads/master' '$committer_date' '$author_date'
	'refs/tags/testtag' '$tagger_date'
	EOF
	(
		git for-each-ref --shell \
			--format="%(refname) %(committerdate${f:+:$f}) %(authordate${f:+:$f})" \
			refs/heads &&
		git for-each-ref --shell \
			--format="%(refname) %(taggerdate${f:+:$f})" \
			refs/tags
	) >actual &&
	test_cmp expected actual
}

test_expect_success 'Check unformatted date fields output' '
	test_date "" \
		"Tue Jul 4 01:18:43 2006 +0200" \
		"Tue Jul 4 01:18:44 2006 +0200" \
		"Tue Jul 4 01:18:45 2006 +0200"
'

test_expect_success 'Check format "default" formatted date fields output' '
	test_date default \
		"Tue Jul 4 01:18:43 2006 +0200" \
		"Tue Jul 4 01:18:44 2006 +0200" \
		"Tue Jul 4 01:18:45 2006 +0200"
'

test_expect_success 'Check format "default-local" date fields output' '
	test_date default-local "Mon Jul 3 23:18:43 2006" "Mon Jul 3 23:18:44 2006" "Mon Jul 3 23:18:45 2006"
'

# Don't know how to do relative check because I can't know when this script
# is going to be run and can't fake the current time to git, and hence can't
# provide expected output.  Instead, I'll just make sure that "relative"
# doesn't exit in error
test_expect_success 'Check format "relative" date fields output' '
	f=relative &&
	(git for-each-ref --shell --format="%(refname) %(committerdate:$f) %(authordate:$f)" refs/heads &&
	git for-each-ref --shell --format="%(refname) %(taggerdate:$f)" refs/tags) >actual
'

# We just check that this is the same as "relative" for now.
test_expect_success 'Check format "relative-local" date fields output' '
	test_date relative-local \
		"$(git for-each-ref --format="%(committerdate:relative)" refs/heads)" \
		"$(git for-each-ref --format="%(authordate:relative)" refs/heads)" \
		"$(git for-each-ref --format="%(taggerdate:relative)" refs/tags)"
'

test_expect_success 'Check format "short" date fields output' '
	test_date short 2006-07-04 2006-07-04 2006-07-04
'

test_expect_success 'Check format "short-local" date fields output' '
	test_date short-local 2006-07-03 2006-07-03 2006-07-03
'

test_expect_success 'Check format "local" date fields output' '
	test_date local \
		"Mon Jul 3 23:18:43 2006" \
		"Mon Jul 3 23:18:44 2006" \
		"Mon Jul 3 23:18:45 2006"
'

test_expect_success 'Check format "iso8601" date fields output' '
	test_date iso8601 \
		"2006-07-04 01:18:43 +0200" \
		"2006-07-04 01:18:44 +0200" \
		"2006-07-04 01:18:45 +0200"
'

test_expect_success 'Check format "iso8601-local" date fields output' '
	test_date iso8601-local "2006-07-03 23:18:43 +0000" "2006-07-03 23:18:44 +0000" "2006-07-03 23:18:45 +0000"
'

test_expect_success 'Check format "rfc2822" date fields output' '
	test_date rfc2822 \
		"Tue, 4 Jul 2006 01:18:43 +0200" \
		"Tue, 4 Jul 2006 01:18:44 +0200" \
		"Tue, 4 Jul 2006 01:18:45 +0200"
'

test_expect_success 'Check format "rfc2822-local" date fields output' '
	test_date rfc2822-local "Mon, 3 Jul 2006 23:18:43 +0000" "Mon, 3 Jul 2006 23:18:44 +0000" "Mon, 3 Jul 2006 23:18:45 +0000"
'

test_expect_success 'Check format "raw" date fields output' '
	test_date raw "1151968723 +0200" "1151968724 +0200" "1151968725 +0200"
'

test_expect_success 'Check format "raw-local" date fields output' '
	test_date raw-local "1151968723 +0000" "1151968724 +0000" "1151968725 +0000"
'

test_expect_success 'Check format of strftime date fields' '
	echo "my date is 2006-07-04" >expected &&
	git for-each-ref \
	  --format="%(authordate:format:my date is %Y-%m-%d)" \
	  refs/heads >actual &&
	test_cmp expected actual
'

test_expect_success 'Check format of strftime-local date fields' '
	echo "my date is 2006-07-03" >expected &&
	git for-each-ref \
	  --format="%(authordate:format-local:my date is %Y-%m-%d)" \
	  refs/heads >actual &&
	test_cmp expected actual
'

test_expect_success 'exercise strftime with odd fields' '
	echo >expected &&
	git for-each-ref --format="%(authordate:format:)" refs/heads >actual &&
	test_cmp expected actual &&
	long="long format -- $_z40$_z40$_z40$_z40$_z40$_z40$_z40" &&
	echo $long >expected &&
	git for-each-ref --format="%(authordate:format:$long)" refs/heads >actual &&
	test_cmp expected actual
'

cat >expected <<\EOF
refs/heads/master
refs/remotes/origin/master
refs/tags/testtag
EOF

test_expect_success 'Verify ascending sort' '
	git for-each-ref --format="%(refname)" --sort=refname >actual &&
	test_cmp expected actual
'


cat >expected <<\EOF
refs/tags/testtag
refs/remotes/origin/master
refs/heads/master
EOF

test_expect_success 'Verify descending sort' '
	git for-each-ref --format="%(refname)" --sort=-refname >actual &&
	test_cmp expected actual
'

cat >expected <<\EOF
'refs/heads/master'
'refs/remotes/origin/master'
'refs/tags/testtag'
EOF

test_expect_success 'Quoting style: shell' '
	git for-each-ref --shell --format="%(refname)" >actual &&
	test_cmp expected actual
'

test_expect_success 'Quoting style: perl' '
	git for-each-ref --perl --format="%(refname)" >actual &&
	test_cmp expected actual
'

test_expect_success 'Quoting style: python' '
	git for-each-ref --python --format="%(refname)" >actual &&
	test_cmp expected actual
'

cat >expected <<\EOF
"refs/heads/master"
"refs/remotes/origin/master"
"refs/tags/testtag"
EOF

test_expect_success 'Quoting style: tcl' '
	git for-each-ref --tcl --format="%(refname)" >actual &&
	test_cmp expected actual
'

for i in "--perl --shell" "-s --python" "--python --tcl" "--tcl --perl"; do
	test_expect_success "more than one quoting style: $i" "
		git for-each-ref $i 2>&1 | (read line &&
		case \$line in
		\"error: more than one quoting style\"*) : happy;;
		*) false
		esac)
	"
done

test_expect_success 'setup for upstream:track[short]' '
	test_commit two
'

test_atom head upstream:track '[ahead 1]'
test_atom head upstream:trackshort '>'
test_atom head push:track '[ahead 1]'
test_atom head push:trackshort '>'

test_expect_success 'Check that :track[short] cannot be used with other atoms' '
	test_must_fail git for-each-ref --format="%(refname:track)" 2>/dev/null &&
	test_must_fail git for-each-ref --format="%(refname:trackshort)" 2>/dev/null
'

test_expect_success 'Check that :track[short] works when upstream is invalid' '
	cat >expected <<-\EOF &&


	EOF
	test_when_finished "git config branch.master.merge refs/heads/master" &&
	git config branch.master.merge refs/heads/does-not-exist &&
	git for-each-ref \
		--format="%(upstream:track)$LF%(upstream:trackshort)" \
		refs/heads >actual &&
	test_cmp expected actual
'

test_expect_success 'Check for invalid refname format' '
	test_must_fail git for-each-ref --format="%(refname:INVALID)"
'

get_color ()
{
	git config --get-color no.such.slot "$1"
}

cat >expected <<EOF
$(git rev-parse --short refs/heads/master) $(get_color green)master$(get_color reset)
$(git rev-parse --short refs/remotes/origin/master) $(get_color green)origin/master$(get_color reset)
$(git rev-parse --short refs/tags/testtag) $(get_color green)testtag$(get_color reset)
$(git rev-parse --short refs/tags/two) $(get_color green)two$(get_color reset)
EOF

test_expect_success 'Check %(color:...) ' '
	git for-each-ref --format="%(objectname:short) %(color:green)%(refname:short)" >actual &&
	test_cmp expected actual
'

cat >expected <<\EOF
heads/master
tags/master
EOF

test_expect_success 'Check ambiguous head and tag refs (strict)' '
	git config --bool core.warnambiguousrefs true &&
	git checkout -b newtag &&
	echo "Using $datestamp" > one &&
	git add one &&
	git commit -m "Branch" &&
	setdate_and_increment &&
	git tag -m "Tagging at $datestamp" master &&
	git for-each-ref --format "%(refname:short)" refs/heads/master refs/tags/master >actual &&
	test_cmp expected actual
'

cat >expected <<\EOF
heads/master
master
EOF

test_expect_success 'Check ambiguous head and tag refs (loose)' '
	git config --bool core.warnambiguousrefs false &&
	git for-each-ref --format "%(refname:short)" refs/heads/master refs/tags/master >actual &&
	test_cmp expected actual
'

cat >expected <<\EOF
heads/ambiguous
ambiguous
EOF

test_expect_success 'Check ambiguous head and tag refs II (loose)' '
	git checkout master &&
	git tag ambiguous testtag^0 &&
	git branch ambiguous testtag^0 &&
	git for-each-ref --format "%(refname:short)" refs/heads/ambiguous refs/tags/ambiguous >actual &&
	test_cmp expected actual
'

test_expect_success 'an unusual tag with an incomplete line' '

	git tag -m "bogo" bogo &&
	bogo=$(git cat-file tag bogo) &&
	bogo=$(printf "%s" "$bogo" | git mktag) &&
	git tag -f bogo "$bogo" &&
	git for-each-ref --format "%(body)" refs/tags/bogo

'

test_expect_success 'create tag with subject and body content' '
	cat >>msg <<-\EOF &&
		the subject line

		first body line
		second body line
	EOF
	git tag -F msg subject-body
'
test_atom refs/tags/subject-body subject 'the subject line'
test_atom refs/tags/subject-body body 'first body line
second body line
'
test_atom refs/tags/subject-body contents 'the subject line

first body line
second body line
'

test_expect_success 'create tag with multiline subject' '
	cat >msg <<-\EOF &&
		first subject line
		second subject line

		first body line
		second body line
	EOF
	git tag -F msg multiline
'
test_atom refs/tags/multiline subject 'first subject line second subject line'
test_atom refs/tags/multiline contents:subject 'first subject line second subject line'
test_atom refs/tags/multiline body 'first body line
second body line
'
test_atom refs/tags/multiline contents:body 'first body line
second body line
'
test_atom refs/tags/multiline contents:signature ''
test_atom refs/tags/multiline contents 'first subject line
second subject line

first body line
second body line
'

test_expect_success GPG 'create signed tags' '
	git tag -s -m "" signed-empty &&
	git tag -s -m "subject line" signed-short &&
	cat >msg <<-\EOF &&
	subject line

	body contents
	EOF
	git tag -s -F msg signed-long
'

sig='-----BEGIN PGP SIGNATURE-----
-----END PGP SIGNATURE-----
'

PREREQ=GPG
test_atom refs/tags/signed-empty subject ''
test_atom refs/tags/signed-empty contents:subject ''
test_atom refs/tags/signed-empty body "$sig"
test_atom refs/tags/signed-empty contents:body ''
test_atom refs/tags/signed-empty contents:signature "$sig"
test_atom refs/tags/signed-empty contents "$sig"

test_atom refs/tags/signed-short subject 'subject line'
test_atom refs/tags/signed-short contents:subject 'subject line'
test_atom refs/tags/signed-short body "$sig"
test_atom refs/tags/signed-short contents:body ''
test_atom refs/tags/signed-short contents:signature "$sig"
test_atom refs/tags/signed-short contents "subject line
$sig"

test_atom refs/tags/signed-long subject 'subject line'
test_atom refs/tags/signed-long contents:subject 'subject line'
test_atom refs/tags/signed-long body "body contents
$sig"
test_atom refs/tags/signed-long contents:body 'body contents
'
test_atom refs/tags/signed-long contents:signature "$sig"
test_atom refs/tags/signed-long contents "subject line

body contents
$sig"

cat >expected <<EOF
$(git rev-parse refs/tags/bogo) <committer@example.com> refs/tags/bogo
$(git rev-parse refs/tags/master) <committer@example.com> refs/tags/master
EOF

test_expect_success 'Verify sort with multiple keys' '
	git for-each-ref --format="%(objectname) %(taggeremail) %(refname)" --sort=objectname --sort=taggeremail \
		refs/tags/bogo refs/tags/master > actual &&
	test_cmp expected actual
'
test_done
