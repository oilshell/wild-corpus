#!/bin/bash
#
# Usage:
#   ./run.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

show-checksum() {
  sha1sum k-script-build-static
}

build() {
  ./configure
  rm -v -f k-script-build-static
  time make k-script-build-static
  ./k-script-build-static --help
  show-checksum
}

# Doesn't run with osh!  See below.
make-osh() {
  ./configure
  rm -v -f k-script-build-static
  time make SHELL=~/git/oilshell/oil/bin/osh k-script-build-static
  ./k-script-build-static --help
  show-checksum
}

osh() {
  ~/git/oilshell/oil/bin/osh "$@"
}

# Copied from 'make' output

# Takes 40.4 seconds, vs 0.6 seconds for bash!  So about 100 times slower.

build-with-osh() {
  rm -v -f k-script-build-static

  export PS4='+${SOURCE_NAME}:${LINENO} '

  # NOTE: Osh hangs right now on read!  I think I have to fix the bug in
  # builtin-io.test.sh.

  pushd src
  #time ./k-script-build.sh \
  #time osh -x \
  time osh \
    ./k-script-build.sh \
    --static \
    --file k-script-build.sh \
    --output ../k-script-build-static \
    --executable #--debug

  # Hm --verbose doesn't do anything?
  # --debug doesn't do anything either?
  popd

  cp k-script-build-static k-script-build-static-OSH
  show-checksum
}

"$@"
