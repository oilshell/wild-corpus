#!/bin/bash
#
# Usage:
#   ./run.sh <function name>

set -o nounset
set -o pipefail
set -o errexit

download() {
  wget 'http://lists.gnu.org/archive/html/bug-bash/2001-02/msg00054.html'
}

unescape() {
  #sed -i 's/&quot;/"/g' shasm.sh
  #sed -i 's/&gt;/>/g' shasm.sh
  sed -i 's/&amp;/\&/g' shasm.sh
}

"$@"
