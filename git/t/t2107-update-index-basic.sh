#!/bin/sh

test_description='basic update-index tests

Tests for command-line parsing and basic operation.
'

. ./test-lib.sh

test_expect_success 'update-index --nonsense fails' '
	test_must_fail git update-index --nonsense 2>msg &&
	cat msg &&
	test -s msg
'

test_expect_success 'update-index --nonsense dumps usage' '
	test_expect_code 129 git update-index --nonsense 2>err &&
	test_i18ngrep "[Uu]sage: git update-index" err
'

test_expect_success 'update-index -h with corrupt index' '
	mkdir broken &&
	(
		cd broken &&
		git init &&
		>.git/index &&
		test_expect_code 129 git update-index -h >usage 2>&1
	) &&
	test_i18ngrep "[Uu]sage: git update-index" broken/usage
'

test_expect_success '--cacheinfo complains of missing arguments' '
	test_must_fail git update-index --cacheinfo
'

test_expect_success '--cacheinfo does not accept blob null sha1' '
	echo content >file &&
	git add file &&
	git rev-parse :file >expect &&
	test_must_fail git update-index --cacheinfo 100644 $_z40 file &&
	git rev-parse :file >actual &&
	test_cmp expect actual
'

test_expect_success '--cacheinfo does not accept gitlink null sha1' '
	git init submodule &&
	(cd submodule && test_commit foo) &&
	git add submodule &&
	git rev-parse :submodule >expect &&
	test_must_fail git update-index --cacheinfo 160000 $_z40 submodule &&
	git rev-parse :submodule >actual &&
	test_cmp expect actual
'

test_expect_success '--cacheinfo mode,sha1,path (new syntax)' '
	echo content >file &&
	git hash-object -w --stdin <file >expect &&

	git update-index --add --cacheinfo 100644 "$(cat expect)" file &&
	git rev-parse :file >actual &&
	test_cmp expect actual &&

	git update-index --add --cacheinfo "100644,$(cat expect),elif" &&
	git rev-parse :elif >actual &&
	test_cmp expect actual
'

test_expect_success '.lock files cleaned up' '
	mkdir cleanup &&
	(
	cd cleanup &&
	mkdir worktree &&
	git init repo &&
	cd repo &&
	git config core.worktree ../../worktree &&
	# --refresh triggers late setup_work_tree,
	# active_cache_changed is zero, rollback_lock_file fails
	git update-index --refresh &&
	! test -f .git/index.lock
	)
'

test_expect_success '--chmod=+x and chmod=-x in the same argument list' '
	>A &&
	>B &&
	git add A B &&
	git update-index --chmod=+x A --chmod=-x B &&
	cat >expect <<-\EOF &&
	100755 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 0	A
	100644 e69de29bb2d1d6434b8b29ae775ad8c2e48c5391 0	B
	EOF
	git ls-files --stage A B >actual &&
	test_cmp expect actual
'

test_done
