#!/bin/bash
#
# Usage:
#   ./run.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

config() {
  cmake -DGO_EXECUTABLE=~/go/bin/go ..
}

build() {
  export GOROOT=~/go
  time make
}


"$@"
