#!/bin/bash
NEEDED_PROGRAMS=( curl git rsync ssh )
FAILED=0
for binary in ${NEEDED_PROGRAMS[@]}; do
  if ! which $binary >/dev/null; then
    FAILED=1
    echo "Unable to locate $binary on the path." >&2
  fi
done

if [[ $FAILED != 0 ]]; then
  echo "Please see above error output to determine which programs you need to install or make available on your path. Aborting." >&2
  exit 1
fi
