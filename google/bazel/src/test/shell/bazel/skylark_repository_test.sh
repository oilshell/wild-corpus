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
#
# Test the local_repository binding
#

# Load the test setup defined in the parent directory
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${CURRENT_DIR}/../integration_test_setup.sh" \
  || { echo "integration_test_setup.sh not found!" >&2; exit 1; }
source "${CURRENT_DIR}/remote_helpers.sh" \
  || { echo "remote_helpers.sh not found!" >&2; exit 1; }

# Basic test.
function test_macro_local_repository() {
  create_new_workspace
  repo2=$new_workspace_dir

  mkdir -p carnivore
  cat > carnivore/BUILD <<'EOF'
genrule(
    name = "mongoose",
    cmd = "echo 'Tra-la!' | tee $@",
    outs = ["moogoose.txt"],
    visibility = ["//visibility:public"],
)
EOF

  cd ${WORKSPACE_DIR}
  cat > WORKSPACE <<EOF
load('/test', 'macro')

macro('$repo2')
EOF

  # Empty package for the .bzl file
  echo -n >BUILD

  # Our macro
  cat >test.bzl <<EOF
def macro(path):
  print('bleh')
  native.local_repository(name='endangered', path=path)
  native.bind(name='mongoose', actual='@endangered//carnivore:mongoose')
EOF
  mkdir -p zoo
  cat > zoo/BUILD <<'EOF'
genrule(
    name = "ball-pit1",
    srcs = ["@endangered//carnivore:mongoose"],
    outs = ["ball-pit1.txt"],
    cmd = "cat $< >$@",
)

genrule(
    name = "ball-pit2",
    srcs = ["//external:mongoose"],
    outs = ["ball-pit2.txt"],
    cmd = "cat $< >$@",
)
EOF

  bazel build //zoo:ball-pit1 >& $TEST_log || fail "Failed to build"
  expect_log "bleh."
  expect_log "Tra-la!"  # Invalidation
  cat bazel-genfiles/zoo/ball-pit1.txt >$TEST_log
  expect_log "Tra-la!"

  bazel build //zoo:ball-pit1 >& $TEST_log || fail "Failed to build"
  expect_not_log "Tra-la!"  # No invalidation

  bazel build //zoo:ball-pit2 >& $TEST_log || fail "Failed to build"
  expect_not_log "Tra-la!"  # No invalidation
  cat bazel-genfiles/zoo/ball-pit2.txt >$TEST_log
  expect_log "Tra-la!"

  # Test invalidation of the WORKSPACE file
  create_new_workspace
  repo2=$new_workspace_dir

  mkdir -p carnivore
  cat > carnivore/BUILD <<'EOF'
genrule(
    name = "mongoose",
    cmd = "echo 'Tra-la-la!' | tee $@",
    outs = ["moogoose.txt"],
    visibility = ["//visibility:public"],
)
EOF
  cd ${WORKSPACE_DIR}
  cat >test.bzl <<EOF
def macro(path):
  print('blah')
  native.local_repository(name='endangered', path='$repo2')
  native.bind(name='mongoose', actual='@endangered//carnivore:mongoose')
EOF
  bazel build //zoo:ball-pit1 >& $TEST_log || fail "Failed to build"
  expect_log "blah."
  expect_log "Tra-la-la!"  # Invalidation
  cat bazel-genfiles/zoo/ball-pit1.txt >$TEST_log
  expect_log "Tra-la-la!"

  bazel build //zoo:ball-pit1 >& $TEST_log || fail "Failed to build"
  expect_not_log "Tra-la-la!"  # No invalidation

  bazel build //zoo:ball-pit2 >& $TEST_log || fail "Failed to build"
  expect_not_log "Tra-la-la!"  # No invalidation
  cat bazel-genfiles/zoo/ball-pit2.txt >$TEST_log
  expect_log "Tra-la-la!"
}

function test_load_from_symlink_to_outside_of_workspace() {
  OTHER=$TEST_TMPDIR/other

  cat > WORKSPACE<<EOF
load("/a/b/c", "c")
EOF

  mkdir -p $OTHER/a/b
  touch $OTHER/a/b/BUILD
  cat > $OTHER/a/b/c.bzl <<EOF
def c():
  pass
EOF

  touch BUILD
  ln -s $TEST_TMPDIR/other/a a
  bazel build //:BUILD || fail "Failed to build"
  rm -fr $TEST_TMPDIR/other
}

# Test load from repository.
function test_external_load_from_workspace() {
  create_new_workspace
  repo2=$new_workspace_dir

  mkdir -p carnivore
  cat > carnivore/BUILD <<'EOF'
genrule(
    name = "mongoose",
    cmd = "echo 'Tra-la-la!' | tee $@",
    outs = ["moogoose.txt"],
    visibility = ["//visibility:public"],
)
EOF

  create_new_workspace
  repo3=$new_workspace_dir
  # Our macro
  cat >WORKSPACE
  cat >test.bzl <<EOF
def macro(path):
  print('bleh')
  native.local_repository(name='endangered', path=path)
EOF
  cat >BUILD <<'EOF'
exports_files(["test.bzl"])
EOF

  cd ${WORKSPACE_DIR}
  cat > WORKSPACE <<EOF
local_repository(name='proxy', path='$repo3')
load('@proxy//:test.bzl', 'macro')
macro('$repo2')
EOF

  bazel build @endangered//carnivore:mongoose >& $TEST_log \
    || fail "Failed to build"
  expect_log "bleh."
}

# Test loading a repository with a load statement in the WORKSPACE file
function test_load_repository_with_load() {
  create_new_workspace
  repo2=$new_workspace_dir

  echo "Tra-la!" > data.txt
  cat <<'EOF' >BUILD
exports_files(["data.txt"])
EOF

  cat <<'EOF' >ext.bzl
def macro():
  print('bleh')
EOF

  cat <<'EOF' >WORKSPACE
workspace(name = "foo")
load("//:ext.bzl", "macro")
macro()
EOF

  cd ${WORKSPACE_DIR}
  cat > WORKSPACE <<EOF
local_repository(name='foo', path='$repo2')
load("@foo//:ext.bzl", "macro")
macro()
EOF

  cat > BUILD <<'EOF'
genrule(name = "foo", srcs=["@foo//:data.txt"], outs=["foo.txt"], cmd = "cat $< | tee $@")
EOF

  bazel build //:foo >& $TEST_log || fail "Failed to build"
  expect_log "bleh"
  expect_log "Tra-la!"
}

# Test cycle when loading a repository with a load statement in the WORKSPACE file that is not
# yet defined.
function test_cycle_load_repository() {
  create_new_workspace
  repo2=$new_workspace_dir

  echo "Tra-la!" > data.txt
  cat <<'EOF' >BUILD
exports_files(["data.txt"])
EOF

  cat <<'EOF' >ext.bzl
def macro():
  print('bleh')
EOF

  cat >WORKSPACE

  cd ${WORKSPACE_DIR}
  cat > WORKSPACE <<EOF
load("@foo//:ext.bzl", "macro")
macro()
local_repository(name='foo', path='$repo2')
EOF

  local exitCode=0
  bazel build @foo//:data.txt >& $TEST_log || exitCode=$?
  [ $exitCode != 0 ] || fail "building @foo//:data.txt succeed while expected failure"

  expect_not_log "PACKAGE"
  expect_log "Failed to load Skylark extension '@foo//:ext.bzl'"
  expect_log "Maybe repository 'foo' was defined later in your WORKSPACE file?"
}

function test_skylark_local_repository() {
  create_new_workspace
  repo2=$new_workspace_dir
  # Remove the WORKSPACE file in the symlinked repo, so our skylark rule has to
  # create one.
  rm $repo2/WORKSPACE

  cat > BUILD <<'EOF'
genrule(name='bar', cmd='echo foo | tee $@', outs=['bar.txt'])
EOF

  cd ${WORKSPACE_DIR}
  cat > WORKSPACE <<EOF
load('/test', 'repo')
repo(name='foo', path='$repo2')
EOF

  # Our custom repository rule
  cat >test.bzl <<EOF
def _impl(repository_ctx):
  repository_ctx.symlink(repository_ctx.path(repository_ctx.attr.path), repository_ctx.path(""))

repo = repository_rule(
    implementation=_impl,
    local=True,
    attrs={"path": attr.string(mandatory=True)})
EOF
  # Need to be in a package
  cat > BUILD

  bazel build @foo//:bar >& $TEST_log || fail "Failed to build"
  expect_log "foo"
  expect_not_log "Workspace name in .*/WORKSPACE (@__main__) does not match the name given in the repository's definition (@foo)"
  cat bazel-genfiles/external/foo/bar.txt >$TEST_log
  expect_log "foo"
}

function setup_skylark_repository() {
  create_new_workspace
  repo2=$new_workspace_dir

  cat > bar.txt
  echo "filegroup(name='bar', srcs=['bar.txt'])" > BUILD

  cd "${WORKSPACE_DIR}"
  cat > WORKSPACE <<EOF
load('/test', 'repo')
repo(name = 'foo')
EOF
  # Need to be in a package
  cat > BUILD
}

function test_skylark_repository_which_and_execute() {
  setup_skylark_repository

  # Test we are using the client environment, not the server one
  bazel info &> /dev/null  # Start up the server.
  echo "#!/bin/bash" > bin.sh
  echo "exit 0" >> bin.sh
  chmod +x bin.sh

  # Our custom repository rule
  cat >test.bzl <<EOF
def _impl(repository_ctx):
  # Symlink so a repository is created
  repository_ctx.symlink(repository_ctx.path("$repo2"), repository_ctx.path(""))
  bash = repository_ctx.which("bash")
  if bash == None:
    fail("Bash not found!")
  bin = repository_ctx.which("bin.sh")
  if bin == None:
    fail("bin.sh not found!")
  result = repository_ctx.execute([bash, "--version"], 10, {"FOO": "BAR"})
  if result.return_code != 0:
    fail("Non-zero return code from bash: " + str(result.return_code))
  if result.stderr != "":
    fail("Non-empty error output: " + result.stderr)
  print(result.stdout)
repo = repository_rule(implementation=_impl, local=True)
EOF

  FOO="BAZ" PATH="${PATH}:${PWD}" bazel build @foo//:bar >& $TEST_log \
      || fail "Failed to build"
  expect_log "version"
}

function test_skylark_repository_execute_stderr() {
  setup_skylark_repository

  cat >test.bzl <<EOF
def _impl(repository_ctx):
  # Symlink so a repository is created
  repository_ctx.symlink(repository_ctx.path("$repo2"), repository_ctx.path(""))
  result = repository_ctx.execute([str(repository_ctx.which("bash")), "-c", "echo erf >&2; exit 1"])
  if result.return_code != 1:
    fail("Incorrect return code from bash: %s != 1\n%s" % (result.return_code, result.stderr))
  if result.stdout != "":
    fail("Non-empty output: %s (stderr was %s)" % (result.stdout, result.stderr))
  print(result.stderr)
repo = repository_rule(implementation=_impl, local=True)
EOF

  bazel build @foo//:bar >& $TEST_log || fail "Failed to build"
  expect_log "erf"
}

function test_skylark_repository_execute_env_and_workdir() {
  setup_skylark_repository

  cat >test.bzl <<EOF
def _impl(repository_ctx):
  # Symlink so a repository is created
  repository_ctx.symlink(repository_ctx.path("$repo2"), repository_ctx.path(""))
  result = repository_ctx.execute(
    [str(repository_ctx.which("bash")), "-c", "echo PWD=\$PWD TOTO=\$TOTO"],
    1000000,
    { "TOTO": "titi" })
  if result.return_code != 0:
    fail("Incorrect return code from bash: %s != 0\n%s" % (result.return_code, result.stderr))
  print(result.stdout)
repo = repository_rule(implementation=_impl, local=True)
EOF

  bazel build @foo//:bar >& $TEST_log || fail "Failed to build"
  expect_log "PWD=$repo2 TOTO=titi"
}

function test_skylark_repository_environ() {
  setup_skylark_repository

  # Our custom repository rule
  cat >test.bzl <<EOF
def _impl(repository_ctx):
  print(repository_ctx.os.environ["FOO"])
  # Symlink so a repository is created
  repository_ctx.symlink(repository_ctx.path("$repo2"), repository_ctx.path(""))
repo = repository_rule(implementation=_impl, local=False)
EOF

  # TODO(dmarting): We should seriously have something better to force a refetch...
  bazel clean --expunge
  FOO=BAR bazel build @foo//:bar >& $TEST_log || fail "Failed to build"
  expect_log "BAR"

  FOO=BAR bazel clean --expunge >& $TEST_log
  FOO=BAR bazel info >& $TEST_log

  FOO=BAZ bazel build @foo//:bar >& $TEST_log || fail "Failed to build"
  expect_log "BAZ"

  # Test that we don't re-run on server restart.
  FOO=BEZ bazel build @foo//:bar >& $TEST_log || fail "Failed to build"
  expect_not_log "BEZ"
  bazel shutdown >& $TEST_log
  FOO=BEZ bazel build @foo//:bar >& $TEST_log || fail "Failed to build"
  expect_not_log "BEZ"

  # Test modifying test.bzl invalidate the repository
  cat >test.bzl <<EOF
def _impl(repository_ctx):
  print(repository_ctx.os.environ["BAR"])
  # Symlink so a repository is created
  repository_ctx.symlink(repository_ctx.path("$repo2"), repository_ctx.path(""))
repo = repository_rule(implementation=_impl, local=True)
EOF
  BAR=BEZ bazel build @foo//:bar >& $TEST_log || fail "Failed to build"
  expect_log "BEZ"

  # Shutdown and modify again
  bazel shutdown
  cat >test.bzl <<EOF
def _impl(repository_ctx):
  print(repository_ctx.os.environ["BAZ"])
  # Symlink so a repository is created
  repository_ctx.symlink(repository_ctx.path("$repo2"), repository_ctx.path(""))
repo = repository_rule(implementation=_impl, local=True)
EOF
  BAZ=BOZ bazel build @foo//:bar >& $TEST_log || fail "Failed to build"
  expect_log "BOZ"
}

function test_skylark_repository_executable_flag() {
  setup_skylark_repository

  # Our custom repository rule
  cat >test.bzl <<EOF
def _impl(repository_ctx):
  repository_ctx.file("test.sh", "exit 0")
  repository_ctx.file("BUILD", "sh_binary(name='bar',srcs=['test.sh'])", False)
  repository_ctx.template("test2", Label("//:bar"), {}, False)
  repository_ctx.template("test2.sh", Label("//:bar"), {}, True)
repo = repository_rule(implementation=_impl, local=True)
EOF
  cat >bar

  bazel run @foo//:bar >& $TEST_log || fail "Execution of @foo//:bar failed"
  output_base=$(bazel info output_base)
  test -x "${output_base}/external/foo/test.sh" || fail "test.sh is not executable"
  test -x "${output_base}/external/foo/test2.sh" || fail "test2.sh is not executable"
  test ! -x "${output_base}/external/foo/BUILD" || fail "BUILD is executable"
  test ! -x "${output_base}/external/foo/test2" || fail "test2 is executable"
}

function test_skylark_repository_download() {
  # Prepare HTTP server with Python
  local server_dir="${TEST_TMPDIR}/server_dir"
  mkdir -p "${server_dir}"
  local download_with_sha256="${server_dir}/download_with_sha256.txt"
  local download_no_sha256="${server_dir}/download_no_sha256.txt"
  local download_executable_file="${server_dir}/download_executable_file.sh"
  echo "This is one file" > "${download_no_sha256}"
  echo "This is another file" > "${download_with_sha256}"
  echo "echo 'I am executable'" > "${download_executable_file}"
  file_sha256="$(sha256sum "${download_with_sha256}" | head -c 64)"

  # Start HTTP server with Python
  startup_server "${server_dir}"

  setup_skylark_repository
  # Our custom repository rule
  cat >test.bzl <<EOF
def _impl(repository_ctx):
  repository_ctx.download(
    "http://localhost:${fileserver_port}/download_no_sha256.txt",
    "download_no_sha256.txt")
  repository_ctx.download(
    "http://localhost:${fileserver_port}/download_with_sha256.txt",
    "download_with_sha256.txt", "${file_sha256}")
  repository_ctx.download(
    "http://localhost:${fileserver_port}/download_executable_file.sh",
    "download_executable_file.sh", executable=True)
  repository_ctx.file("BUILD")  # necessary directories should already created by download function
repo = repository_rule(implementation=_impl, local=False)
EOF

  bazel build @foo//:all >& $TEST_log && shutdown_server \
    || fail "Execution of @foo//:all failed"

  output_base="$(bazel info output_base)"
  # Test download
  test -e "${output_base}/external/foo/download_no_sha256.txt" \
    || fail "download_no_sha256.txt is not downloaded"
  test -e "${output_base}/external/foo/download_with_sha256.txt" \
    || fail "download_with_sha256.txt is not downloaded"
  test -e "${output_base}/external/foo/download_executable_file.sh" \
    || fail "download_executable_file.sh is not downloaded"
  # Test download
  diff "${output_base}/external/foo/download_no_sha256.txt" \
    "${download_no_sha256}" >/dev/null \
    || fail "download_no_sha256.txt is not downloaded successfully"
  diff "${output_base}/external/foo/download_with_sha256.txt" \
    "${download_with_sha256}" >/dev/null \
    || fail "download_with_sha256.txt is not downloaded successfully"
  diff "${output_base}/external/foo/download_executable_file.sh" \
    "${download_executable_file}" >/dev/null \
    || fail "download_executable_file.sh is not downloaded successfully"
  # Test executable
  test ! -x "${output_base}/external/foo/download_no_sha256.txt" \
    || fail "download_no_sha256.txt is executable"
  test ! -x "${output_base}/external/foo/download_with_sha256.txt" \
    || fail "download_with_sha256.txt is executable"
  test -x "${output_base}/external/foo/download_executable_file.sh" \
    || fail "download_executable_file.sh is not executable"
}

function test_skylark_repository_download_and_extract() {
  # Prepare HTTP server with Python
  local server_dir="${TEST_TMPDIR}/server_dir"
  mkdir -p "${server_dir}"
  local file_prefix="${server_dir}/download_and_extract"

  pushd ${TEST_TMPDIR}
  echo "This is one file" > server_dir/download_and_extract1.txt
  echo "This is another file" > server_dir/download_and_extract2.txt
  echo "This is a third file" > server_dir/download_and_extract3.txt
  tar -zcvf server_dir/download_and_extract1.tar.gz server_dir/download_and_extract1.txt
  zip server_dir/download_and_extract2.zip server_dir/download_and_extract2.txt
  zip server_dir/download_and_extract3.zip server_dir/download_and_extract3.txt
  file_sha256="$(sha256sum server_dir/download_and_extract3.zip | head -c 64)"
  popd

  # Start HTTP server with Python
  startup_server "${server_dir}"

  setup_skylark_repository
  # Our custom repository rule
  cat >test.bzl <<EOF
def _impl(repository_ctx):
  repository_ctx.file("BUILD")
  repository_ctx.download_and_extract(
    "http://localhost:${fileserver_port}/download_and_extract1.tar.gz", "")
  repository_ctx.download_and_extract(
    "http://localhost:${fileserver_port}/download_and_extract2.zip", "", "")
  repository_ctx.download_and_extract(
    "http://localhost:${fileserver_port}/download_and_extract1.tar.gz", "some/path")
  repository_ctx.download_and_extract(
    "http://localhost:${fileserver_port}/download_and_extract3.zip", ".", "${file_sha256}", "", "")
repo = repository_rule(implementation=_impl, local=False)
EOF

  bazel clean --expunge_async >& $TEST_log || fail "bazel clean failed"
  bazel build @foo//:all >& $TEST_log && shutdown_server \
    || fail "Execution of @foo//:all failed"

  output_base="$(bazel info output_base)"
  # Test cleanup
  test -e "${output_base}/external/foo/server_dir/download_and_extract1.tar.gz" \
    && fail "temp file was not deleted successfully" || true
  test -e "${output_base}/external/foo/server_dir/download_and_extract2.zip" \
    && fail "temp file was not deleted successfully" || true
  test -e "${output_base}/external/foo/server_dir/download_and_extract3.zip" \
    && fail "temp file was not deleted successfully" || true
  # Test download_and_extract
  diff "${output_base}/external/foo/server_dir/download_and_extract1.txt" \
    "${file_prefix}1.txt" >/dev/null \
    || fail "download_and_extract1.tar.gz was not extracted successfully"
  diff "${output_base}/external/foo/some/path/server_dir/download_and_extract1.txt" \
    "${file_prefix}1.txt" >/dev/null \
    || fail "download_and_extract1.tar.gz was not extracted successfully in some/path"
  diff "${output_base}/external/foo/server_dir/download_and_extract2.txt" \
    "${file_prefix}2.txt" >/dev/null \
    || fail "download_and_extract2.zip was not extracted successfully"
  diff "${output_base}/external/foo/server_dir/download_and_extract3.txt" \
    "${file_prefix}3.txt" >/dev/null \
    || fail "download_and_extract3.zip was not extracted successfully"
}

# Test native.bazel_version
function test_bazel_version() {
  create_new_workspace
  repo2=$new_workspace_dir

  cat > BUILD <<'EOF'
genrule(
    name = "test",
    cmd = "echo 'Tra-la!' | tee $@",
    outs = ["test.txt"],
    visibility = ["//visibility:public"],
)
EOF

  cd ${WORKSPACE_DIR}
  cat > WORKSPACE <<EOF
load('/test', 'macro')

macro('$repo2')
EOF

  # Empty package for the .bzl file
  echo -n >BUILD

  # Our macro
  cat >test.bzl <<EOF
def macro(path):
  print(native.bazel_version)
  native.local_repository(name='test', path=path)
EOF

  local version="$(bazel info release)"
  # On release, Bazel binary get stamped, else we might run with an unstamped version.
  if [ "$version" == "development version" ]; then
    version=""
  else
    version="${version#* }"
  fi
  bazel build @test//:test >& $TEST_log || fail "Failed to build"
  expect_log ": ${version}."
}


# Test native.existing_rule(s), regression test for #1277
function test_existing_rule() {
  create_new_workspace
  repo2=$new_workspace_dir

  cat > BUILD
  cat > WORKSPACE

  cd ${WORKSPACE_DIR}
  cat > WORKSPACE <<EOF
local_repository(name = 'existing', path='$repo2')
load('/test', 'macro')

macro()
EOF

  # Empty package for the .bzl file
  echo -n >BUILD

  # Our macro
  cat >test.bzl <<EOF
def test(s):
  print("%s = %s,%s" % (s,
                        native.existing_rule(s) != None,
                        s in native.existing_rules()))
def macro():
  test("existing")
  test("non_existing")
EOF

  bazel query //... >& $TEST_log || fail "Failed to build"
  expect_log "existing = True,True"
  expect_log "non_existing = False,False"
}

function test_build_a_repo() {
  cat > WORKSPACE <<EOF
load("//:repo.bzl", "my_repo")
my_repo(name = "reg")
EOF

  cat > repo.bzl <<EOF
def _impl(repository_ctx):
  pass

my_repo = repository_rule(_impl)
EOF

  bazel build //external:reg &> $TEST_log || fail "Couldn't build repo"
}

function tear_down() {
  shutdown_server
  if [ -d "${TEST_TMPDIR}/server_dir" ]; then
    rm -fr "${TEST_TMPDIR}/server_dir"
  fi
  true
}

run_suite "local repository tests"
