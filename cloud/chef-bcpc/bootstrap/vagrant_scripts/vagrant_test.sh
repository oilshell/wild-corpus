#!/bin/bash

. $REPO_ROOT/bootstrap/shared/shared_functions.sh

if ! which vagrant >/dev/null; then
  echo "You must have Vagrant installed to build an environment using Vagrant." >&2
  exit 1
fi
