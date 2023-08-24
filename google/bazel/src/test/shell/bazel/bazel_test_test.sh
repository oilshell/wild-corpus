#!/bin/bash
#
# Copyright 2015 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eu

# Load the test setup defined in the parent directory
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CURRENT_DIR}/../integration_test_setup.sh" \
  || { echo "integration_test_setup.sh not found!" >&2; exit 1; }

function set_up_jobcount() {
  tmp=$(mktemp -d ${TEST_TMPDIR}/testjobs.XXXXXXXX)

  # We use hardlinks to this file as a communication mechanism between
  # test runs.
  touch ${tmp}/counter

  mkdir -p dir

  cat <<EOF > dir/test.sh
#!/bin/bash
# hard link
z=\$(mktemp -u ${tmp}/tmp.XXXXXXXX)
ln ${tmp}/counter \${z}

# Make sure other test runs have started too.
sleep 1
nlink=\$(ls -l ${tmp}/counter | awk '{print \$2}')

# 4 links = 3 jobs + ${tmp}/counter
if [[ "\$nlink" -gt 4 ]] ; then
  echo found "\$nlink" hard links to file, want 4 max.
  exit 1
fi

# Ensure that we don't remove before other runs have inspected the file.
sleep 1
rm \${z}

EOF

  chmod +x dir/test.sh

  cat <<EOF > dir/BUILD
sh_test(
  name = "test",
  srcs = [ "test.sh" ],
  size = "small",
)
EOF
}

# We have to use --spawn_strategy=standalone, because the test actions
# communicate with each other via a hard-linked file.
function test_3_cpus() {
  set_up_jobcount
  # 3 CPUs, so no more than 3 tests in parallel.
  bazel test --spawn_strategy=standalone --test_output=errors \
    --local_resources=10000,3,100  --runs_per_test=10 //dir:test
}

function test_3_local_jobs() {
  set_up_jobcount
  # 3 local test jobs, so no more than 3 tests in parallel.
  bazel test --spawn_strategy=standalone --test_output=errors \
    --local_test_jobs=3 --local_resources=10000,10,100 \
    --runs_per_test=10 //dir:test
}

function test_tmpdir() {
  mkdir -p foo
  cat > foo/bar_test.sh <<'EOF'
#!/bin/bash
echo TEST_TMPDIR=$TEST_TMPDIR
EOF
  chmod +x foo/bar_test.sh
  cat > foo/BUILD <<EOF
sh_test(
    name = "bar_test",
    srcs = ["bar_test.sh"],
)
EOF
  bazel test --test_output=all //foo:bar_test >& $TEST_log || \
    fail "Running sh_test failed"
  expect_log "TEST_TMPDIR=/.*"

  bazel test --nocache_test_results --test_output=all --test_tmpdir=$TEST_TMPDIR //foo:bar_test \
    >& $TEST_log || fail "Running sh_test failed"
  expect_log "TEST_TMPDIR=$TEST_TMPDIR"

  # If we run `bazel test //src/test/shell/bazel:bazel_test_test` on Linux, it
  # will be sandboxed and this "inner test" creating /foo/bar will actually
  # succeed. If we run it on OS X (or in general without sandboxing enabled),
  # it will fail to create /foo/bar, since obviously we don't have write
  # permissions.
  if bazel test --nocache_test_results --test_output=all \
    --test_tmpdir=/foo/bar //foo:bar_test >& $TEST_log; then
    # We are in a sandbox.
    expect_log "TEST_TMPDIR=/foo/bar"
  else
    # We are not sandboxed.
    expect_log "Could not create TEST_TMPDIR"
  fi
}

function test_env_vars() {
  cat > WORKSPACE <<EOF
workspace(name = "bar")
EOF
  mkdir -p foo
  cat > foo/testenv.sh <<'EOF'
#!/bin/bash
echo "pwd: $PWD"
echo "src: $TEST_SRCDIR"
echo "ws: $TEST_WORKSPACE"
EOF
  chmod +x foo/testenv.sh
  cat > foo/BUILD <<EOF
sh_test(
    name = "foo",
    srcs = ["testenv.sh"],
)
EOF

  bazel test --test_output=all //foo &> $TEST_log || fail "Test failed"
  expect_log "pwd: .*/foo.runfiles/bar$"
  expect_log "src: .*/foo.runfiles$"
  expect_log "ws: bar$"
}

function test_run_under_label_with_options() {
  mkdir -p testing run || fail "mkdir testing run failed"
  cat <<EOF > run/BUILD
sh_binary(
  name='under', srcs=['under.sh'],
  visibility=["//visibility:public"],
)
EOF

  cat <<EOF > run/under.sh
#!/bin/sh
echo running under //run:under "\$*"
EOF
  chmod u+x run/under.sh

  cat <<EOF > testing/passing_test.sh
#!/bin/sh
exit 0
EOF
  chmod u+x testing/passing_test.sh

  cat <<EOF > testing/BUILD
sh_test(
  name = "passing_test" ,
  srcs = [ "passing_test.sh" ])
EOF

  bazel test //testing:passing_test --run_under='//run:under -c' \
    --test_output=all >& $TEST_log || fail "Expected success"
  expect_log 'running under //run:under -c testing/passing_test'
  expect_log 'passing_test *PASSED'
  expect_log '1 test passes.$'
}

function test_run_under_path() {
  mkdir -p testing || fail "mkdir testing failed"
  echo "sh_test(name='t1', srcs=['t1.sh'])" > testing/BUILD
  cat <<EOF > testing/t1.sh
#!/bin/sh
exit 0
EOF
  chmod u+x testing/t1.sh

  mkdir -p scripts
  cat <<EOF > scripts/hello
#!/bin/sh
echo "hello script!!!" "\$@"
EOF
  chmod u+x scripts/hello

  PATH=$PATH:$PWD/scripts bazel test //testing:t1 -s --run_under=hello \
    --test_output=all >& $TEST_log || fail "Expected success"
  expect_log 'hello script!!! testing/t1'

  # Make sure it still works if --run_under includes an arg.
  PATH=$PATH:$PWD/scripts bazel test //testing:t1 \
    -s --run_under='hello "some_arg   with"          space' \
    --test_output=all >& $TEST_log || fail "Expected success"
  expect_log 'hello script!!! some_arg   with space testing/t1'

  # Make sure absolute path works also
  bazel test //testing:t1 --run_under=$PWD/scripts/hello \
    -s --test_output=all >& $TEST_log || fail "Expected success"
  expect_log 'hello script!!! testing/t1'
}

function test_test_timeout() {
  mkdir -p dir

  cat <<EOF > dir/test.sh
#!/bin/sh
sleep 3
exit 0

EOF

  chmod +x dir/test.sh

  cat <<EOF > dir/BUILD
  sh_test(
    name = "test",
    timeout = "short",
    srcs = [ "test.sh" ],
    size = "small",
  )
EOF

  bazel test --test_timeout=2 //dir:test &> $TEST_log && fail "should have timed out"
  expect_log "TIMEOUT"
  bazel test --test_timeout=20 //dir:test || fail "expected success"
}

# Makes sure that runs_per_test_detects_flakes detects FLAKY if any of the 5
# attempts passes (which should cover all cases of being picky about the
# first/last/etc ones only being counted).
# We do this using an un-sandboxed test which keeps track of how many runs there
# have been using files which are undeclared inputs/outputs.
function test_runs_per_test_detects_flakes() {
  # Directory for counters
  local COUNTER_DIR="${TEST_TMPDIR}/counter_dir"
  mkdir -p "${COUNTER_DIR}"

  for (( i = 1 ; i <= 5 ; i++ )); do

    # This file holds the number of the next run
    echo 1 > "${COUNTER_DIR}/$i"
    cat <<EOF > test$i.sh
#!/bin/bash
i=\$(< "${COUNTER_DIR}/$i")

# increment the hidden state
echo \$((i + 1)) > "${COUNTER_DIR}/$i"

# succeed exactly once.
exit \$((i != $i))
}
EOF
    chmod +x test$i.sh
    cat <<EOF > BUILD
sh_test(name = "test$i", srcs = [ "test$i.sh" ])
EOF
    bazel test --spawn_strategy=standalone --jobs=1 \
        --runs_per_test=5 --runs_per_test_detects_flakes \
        //:test$i &> $TEST_log || fail "should have succeeded"
    expect_log "FLAKY"
  done
}

# Tests that the test.xml is extracted from the sandbox correctly.
function test_xml_is_present() {
  mkdir -p dir

  cat <<'EOF' > dir/test.sh
#!/bin/sh
echo HELLO > $XML_OUTPUT_FILE
exit 0
EOF

  chmod +x dir/test.sh

  cat <<'EOF' > dir/BUILD
  sh_test(
    name = "test",
    srcs = [ "test.sh" ],
  )
EOF

  bazel test -s --test_output=streamed //dir:test &> $TEST_log || fail "expected success"

  xml_log=bazel-testlogs/dir/test/test.xml
  [ -s $xml_log ] || fail "$xml_log was not present after test"
}

# Simple test that we actually enforce testonly, see #1923.
function test_testonly_is_enforced() {
  mkdir -p testonly
  cat <<'EOF' >testonly/BUILD
genrule(
    name = "testonly",
    srcs = [],
    cmd = "echo testonly | tee $@",
    outs = ["testonly.txt"],
    testonly = 1,
)
genrule(
    name = "not-testonly",
    srcs = [":testonly"],
    cmd = "echo should fail | tee $@",
    outs = ["not-testonly.txt"],
)
EOF
    bazel build //testonly &>$TEST_log || fail "Building //testonly failed"
    bazel build //testonly:not-testonly &>$TEST_log && fail "Should have failed" || true
    expect_log "'//testonly:not-testonly' depends on testonly target '//testonly:testonly'"
}

function test_always_xml_output() {
  mkdir -p dir

  cat <<EOF > dir/success.sh
#!/bin/sh
exit 0
EOF
  cat <<EOF > dir/fail.sh
#!/bin/sh
exit 1
EOF

  chmod +x dir/{success,fail}.sh

  cat <<EOF > dir/BUILD
sh_test(
    name = "success",
    srcs = [ "success.sh" ],
)
sh_test(
    name = "fail",
    srcs = [ "fail.sh" ],
)
EOF

  bazel test //dir:all &> $TEST_log && fail "should have failed" || true
  [ -f "bazel-testlogs/dir/success/test.xml" ] \
    || fail "No xml file for //dir:success"
  [ -f "bazel-testlogs/dir/fail/test.xml" ] \
    || fail "No xml file for //dir:fail"

  cat bazel-testlogs/dir/success/test.xml >$TEST_log
  expect_log "errors=\"0\""
  expect_log_once "testcase"
  expect_log "name=\"dir/success\""
  cat bazel-testlogs/dir/fail/test.xml >$TEST_log
  expect_log "errors=\"1\""
  expect_log_once "testcase"
  expect_log "name=\"dir/fail\""
}

function test_detailed_test_summary() {
  copy_examples
  cat > WORKSPACE <<EOF
workspace(name = "io_bazel")
EOF
  setup_javatest_support

  local java_native_tests=//examples/java-native/src/test/java/com/example/myproject

  bazel test --test_summary=detailed "${java_native_tests}:fail" >& $TEST_log \
    && fail "Test $* succeed while expecting failure" \
    || true
  expect_log 'FAILED.*com\.example\.myproject\.Fail\.testFail'
}

run_suite "test tests"
