#!/bin/sh

test_description='Test handling of ref names that check-ref-format rejects'
. ./test-lib.sh

test_expect_success setup '
	test_commit one &&
	test_commit two
'

test_expect_success 'fast-import: fail on invalid branch name ".badbranchname"' '
	test_when_finished "rm -f .git/objects/pack_* .git/objects/index_*" &&
	cat >input <<-INPUT_END &&
		commit .badbranchname
		committer $GIT_COMMITTER_NAME <$GIT_COMMITTER_EMAIL> $GIT_COMMITTER_DATE
		data <<COMMIT
		corrupt
		COMMIT

		from refs/heads/master

	INPUT_END
	test_must_fail git fast-import <input
'

test_expect_success 'fast-import: fail on invalid branch name "bad[branch]name"' '
	test_when_finished "rm -f .git/objects/pack_* .git/objects/index_*" &&
	cat >input <<-INPUT_END &&
		commit bad[branch]name
		committer $GIT_COMMITTER_NAME <$GIT_COMMITTER_EMAIL> $GIT_COMMITTER_DATE
		data <<COMMIT
		corrupt
		COMMIT

		from refs/heads/master

	INPUT_END
	test_must_fail git fast-import <input
'

test_expect_success 'git branch shows badly named ref as warning' '
	cp .git/refs/heads/master .git/refs/heads/broken...ref &&
	test_when_finished "rm -f .git/refs/heads/broken...ref" &&
	git branch >output 2>error &&
	test_i18ngrep -e "ignoring ref with broken name refs/heads/broken\.\.\.ref" error &&
	! grep -e "broken\.\.\.ref" output
'

test_expect_success 'branch -d can delete badly named ref' '
	cp .git/refs/heads/master .git/refs/heads/broken...ref &&
	test_when_finished "rm -f .git/refs/heads/broken...ref" &&
	git branch -d broken...ref &&
	git branch >output 2>error &&
	! grep -e "broken\.\.\.ref" error &&
	! grep -e "broken\.\.\.ref" output
'

test_expect_success 'branch -D can delete badly named ref' '
	cp .git/refs/heads/master .git/refs/heads/broken...ref &&
	test_when_finished "rm -f .git/refs/heads/broken...ref" &&
	git branch -D broken...ref &&
	git branch >output 2>error &&
	! grep -e "broken\.\.\.ref" error &&
	! grep -e "broken\.\.\.ref" output
'

test_expect_success 'branch -D cannot delete non-ref in .git dir' '
	echo precious >.git/my-private-file &&
	echo precious >expect &&
	test_must_fail git branch -D ../../my-private-file &&
	test_cmp expect .git/my-private-file
'

test_expect_success 'branch -D cannot delete ref in .git dir' '
	git rev-parse HEAD >.git/my-private-file &&
	git rev-parse HEAD >expect &&
	git branch foo/legit &&
	test_must_fail git branch -D foo////./././../../../my-private-file &&
	test_cmp expect .git/my-private-file
'

test_expect_success 'branch -D cannot delete absolute path' '
	git branch -f extra &&
	test_must_fail git branch -D "$(pwd)/.git/refs/heads/extra" &&
	test_cmp_rev HEAD extra
'

test_expect_success 'git branch cannot create a badly named ref' '
	test_when_finished "rm -f .git/refs/heads/broken...ref" &&
	test_must_fail git branch broken...ref &&
	git branch >output 2>error &&
	! grep -e "broken\.\.\.ref" error &&
	! grep -e "broken\.\.\.ref" output
'

test_expect_success 'branch -m cannot rename to a bad ref name' '
	test_when_finished "rm -f .git/refs/heads/broken...ref" &&
	test_might_fail git branch -D goodref &&
	git branch goodref &&
	test_must_fail git branch -m goodref broken...ref &&
	test_cmp_rev master goodref &&
	git branch >output 2>error &&
	! grep -e "broken\.\.\.ref" error &&
	! grep -e "broken\.\.\.ref" output
'

test_expect_failure 'branch -m can rename from a bad ref name' '
	cp .git/refs/heads/master .git/refs/heads/broken...ref &&
	test_when_finished "rm -f .git/refs/heads/broken...ref" &&
	git branch -m broken...ref renamed &&
	test_cmp_rev master renamed &&
	git branch >output 2>error &&
	! grep -e "broken\.\.\.ref" error &&
	! grep -e "broken\.\.\.ref" output
'

test_expect_success 'push cannot create a badly named ref' '
	test_when_finished "rm -f .git/refs/heads/broken...ref" &&
	test_must_fail git push "file://$(pwd)" HEAD:refs/heads/broken...ref &&
	git branch >output 2>error &&
	! grep -e "broken\.\.\.ref" error &&
	! grep -e "broken\.\.\.ref" output
'

test_expect_failure 'push --mirror can delete badly named ref' '
	top=$(pwd) &&
	git init src &&
	git init dest &&

	(
		cd src &&
		test_commit one
	) &&
	(
		cd dest &&
		test_commit two &&
		git checkout --detach &&
		cp .git/refs/heads/master .git/refs/heads/broken...ref
	) &&
	git -C src push --mirror "file://$top/dest" &&
	git -C dest branch >output 2>error &&
	! grep -e "broken\.\.\.ref" error &&
	! grep -e "broken\.\.\.ref" output
'

test_expect_success 'rev-parse skips symref pointing to broken name' '
	test_when_finished "rm -f .git/refs/heads/broken...ref" &&
	git branch shadow one &&
	cp .git/refs/heads/master .git/refs/heads/broken...ref &&
	printf "ref: refs/heads/broken...ref\n" >.git/refs/tags/shadow &&
	test_when_finished "rm -f .git/refs/tags/shadow" &&
	git rev-parse --verify one >expect &&
	git rev-parse --verify shadow >actual 2>err &&
	test_cmp expect actual &&
	test_i18ngrep "ignoring dangling symref refs/tags/shadow" err
'

test_expect_success 'for-each-ref emits warnings for broken names' '
	cp .git/refs/heads/master .git/refs/heads/broken...ref &&
	test_when_finished "rm -f .git/refs/heads/broken...ref" &&
	printf "ref: refs/heads/broken...ref\n" >.git/refs/heads/badname &&
	test_when_finished "rm -f .git/refs/heads/badname" &&
	printf "ref: refs/heads/master\n" >.git/refs/heads/broken...symref &&
	test_when_finished "rm -f .git/refs/heads/broken...symref" &&
	git for-each-ref >output 2>error &&
	! grep -e "broken\.\.\.ref" output &&
	! grep -e "badname" output &&
	! grep -e "broken\.\.\.symref" output &&
	test_i18ngrep "ignoring ref with broken name refs/heads/broken\.\.\.ref" error &&
	test_i18ngrep "ignoring broken ref refs/heads/badname" error &&
	test_i18ngrep "ignoring ref with broken name refs/heads/broken\.\.\.symref" error
'

test_expect_success 'update-ref -d can delete broken name' '
	cp .git/refs/heads/master .git/refs/heads/broken...ref &&
	test_when_finished "rm -f .git/refs/heads/broken...ref" &&
	git update-ref -d refs/heads/broken...ref >output 2>error &&
	test_must_be_empty output &&
	test_must_be_empty error &&
	git branch >output 2>error &&
	! grep -e "broken\.\.\.ref" error &&
	! grep -e "broken\.\.\.ref" output
'

test_expect_success 'branch -d can delete broken name' '
	cp .git/refs/heads/master .git/refs/heads/broken...ref &&
	test_when_finished "rm -f .git/refs/heads/broken...ref" &&
	git branch -d broken...ref >output 2>error &&
	test_i18ngrep "Deleted branch broken...ref (was broken)" output &&
	test_must_be_empty error &&
	git branch >output 2>error &&
	! grep -e "broken\.\.\.ref" error &&
	! grep -e "broken\.\.\.ref" output
'

test_expect_success 'update-ref --no-deref -d can delete symref to broken name' '
	cp .git/refs/heads/master .git/refs/heads/broken...ref &&
	test_when_finished "rm -f .git/refs/heads/broken...ref" &&
	printf "ref: refs/heads/broken...ref\n" >.git/refs/heads/badname &&
	test_when_finished "rm -f .git/refs/heads/badname" &&
	git update-ref --no-deref -d refs/heads/badname >output 2>error &&
	test_path_is_missing .git/refs/heads/badname &&
	test_must_be_empty output &&
	test_must_be_empty error
'

test_expect_success 'branch -d can delete symref to broken name' '
	cp .git/refs/heads/master .git/refs/heads/broken...ref &&
	test_when_finished "rm -f .git/refs/heads/broken...ref" &&
	printf "ref: refs/heads/broken...ref\n" >.git/refs/heads/badname &&
	test_when_finished "rm -f .git/refs/heads/badname" &&
	git branch -d badname >output 2>error &&
	test_path_is_missing .git/refs/heads/badname &&
	test_i18ngrep "Deleted branch badname (was refs/heads/broken\.\.\.ref)" output &&
	test_must_be_empty error
'

test_expect_success 'update-ref --no-deref -d can delete dangling symref to broken name' '
	printf "ref: refs/heads/broken...ref\n" >.git/refs/heads/badname &&
	test_when_finished "rm -f .git/refs/heads/badname" &&
	git update-ref --no-deref -d refs/heads/badname >output 2>error &&
	test_path_is_missing .git/refs/heads/badname &&
	test_must_be_empty output &&
	test_must_be_empty error
'

test_expect_success 'branch -d can delete dangling symref to broken name' '
	printf "ref: refs/heads/broken...ref\n" >.git/refs/heads/badname &&
	test_when_finished "rm -f .git/refs/heads/badname" &&
	git branch -d badname >output 2>error &&
	test_path_is_missing .git/refs/heads/badname &&
	test_i18ngrep "Deleted branch badname (was refs/heads/broken\.\.\.ref)" output &&
	test_must_be_empty error
'

test_expect_success 'update-ref -d can delete broken name through symref' '
	cp .git/refs/heads/master .git/refs/heads/broken...ref &&
	test_when_finished "rm -f .git/refs/heads/broken...ref" &&
	printf "ref: refs/heads/broken...ref\n" >.git/refs/heads/badname &&
	test_when_finished "rm -f .git/refs/heads/badname" &&
	git update-ref -d refs/heads/badname >output 2>error &&
	test_path_is_missing .git/refs/heads/broken...ref &&
	test_must_be_empty output &&
	test_must_be_empty error
'

test_expect_success 'update-ref --no-deref -d can delete symref with broken name' '
	printf "ref: refs/heads/master\n" >.git/refs/heads/broken...symref &&
	test_when_finished "rm -f .git/refs/heads/broken...symref" &&
	git update-ref --no-deref -d refs/heads/broken...symref >output 2>error &&
	test_path_is_missing .git/refs/heads/broken...symref &&
	test_must_be_empty output &&
	test_must_be_empty error
'

test_expect_success 'branch -d can delete symref with broken name' '
	printf "ref: refs/heads/master\n" >.git/refs/heads/broken...symref &&
	test_when_finished "rm -f .git/refs/heads/broken...symref" &&
	git branch -d broken...symref >output 2>error &&
	test_path_is_missing .git/refs/heads/broken...symref &&
	test_i18ngrep "Deleted branch broken...symref (was refs/heads/master)" output &&
	test_must_be_empty error
'

test_expect_success 'update-ref --no-deref -d can delete dangling symref with broken name' '
	printf "ref: refs/heads/idonotexist\n" >.git/refs/heads/broken...symref &&
	test_when_finished "rm -f .git/refs/heads/broken...symref" &&
	git update-ref --no-deref -d refs/heads/broken...symref >output 2>error &&
	test_path_is_missing .git/refs/heads/broken...symref &&
	test_must_be_empty output &&
	test_must_be_empty error
'

test_expect_success 'branch -d can delete dangling symref with broken name' '
	printf "ref: refs/heads/idonotexist\n" >.git/refs/heads/broken...symref &&
	test_when_finished "rm -f .git/refs/heads/broken...symref" &&
	git branch -d broken...symref >output 2>error &&
	test_path_is_missing .git/refs/heads/broken...symref &&
	test_i18ngrep "Deleted branch broken...symref (was refs/heads/idonotexist)" output &&
	test_must_be_empty error
'

test_expect_success 'update-ref -d cannot delete non-ref in .git dir' '
	echo precious >.git/my-private-file &&
	echo precious >expect &&
	test_must_fail git update-ref -d my-private-file >output 2>error &&
	test_must_be_empty output &&
	test_i18ngrep -e "refusing to update ref with bad name" error &&
	test_cmp expect .git/my-private-file
'

test_expect_success 'update-ref -d cannot delete absolute path' '
	git branch -f extra &&
	test_must_fail git update-ref -d "$(pwd)/.git/refs/heads/extra" &&
	test_cmp_rev HEAD extra
'

test_expect_success 'update-ref --stdin fails create with bad ref name' '
	echo "create ~a refs/heads/master" >stdin &&
	test_must_fail git update-ref --stdin <stdin 2>err &&
	grep "fatal: invalid ref format: ~a" err
'

test_expect_success 'update-ref --stdin fails update with bad ref name' '
	echo "update ~a refs/heads/master" >stdin &&
	test_must_fail git update-ref --stdin <stdin 2>err &&
	grep "fatal: invalid ref format: ~a" err
'

test_expect_success 'update-ref --stdin fails delete with bad ref name' '
	echo "delete ~a refs/heads/master" >stdin &&
	test_must_fail git update-ref --stdin <stdin 2>err &&
	grep "fatal: invalid ref format: ~a" err
'

test_expect_success 'update-ref --stdin -z fails create with bad ref name' '
	printf "%s\0" "create ~a " refs/heads/master >stdin &&
	test_must_fail git update-ref -z --stdin <stdin 2>err &&
	grep "fatal: invalid ref format: ~a " err
'

test_expect_success 'update-ref --stdin -z fails update with bad ref name' '
	printf "%s\0" "update ~a" refs/heads/master "" >stdin &&
	test_must_fail git update-ref -z --stdin <stdin 2>err &&
	grep "fatal: invalid ref format: ~a" err
'

test_expect_success 'update-ref --stdin -z fails delete with bad ref name' '
	printf "%s\0" "delete ~a" refs/heads/master >stdin &&
	test_must_fail git update-ref -z --stdin <stdin 2>err &&
	grep "fatal: invalid ref format: ~a" err
'

test_done
