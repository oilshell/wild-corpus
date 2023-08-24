#!/bin/bash
# -*- mode: shell-script; fill-column: 80; -*-
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright (c) 2014, Joyent, Inc.
#

set -o xtrace

SOURCE="${BASH_SOURCE[0]}"
if [[ -h $SOURCE ]]; then
    SOURCE="$(readlink "$SOURCE")"
fi
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
PROFILE=/root/.bashrc
SVC_ROOT=/opt/smartdc/marlin

source ${DIR}/scripts/util.sh
source ${DIR}/scripts/services.sh


export PATH=/opt/local/bin:/usr/sbin:/usr/bin:$PATH
export PATH=$SVC_ROOT/build/node/bin:$SVC_ROOT/node_modules/.bin:$PATH


function manta_setup_marlin {
    svccfg import /opt/smartdc/marlin/smf/manifests/jobsupervisor.xml
    svcadm enable jobsupervisor || fatal "unable to start marlin"
}


# Mainline

echo "Running common setup scripts"
manta_common_presetup

echo "Adding local manifest directories"
manta_add_manifest_dir "/opt/smartdc/marlin"

manta_common_setup "jobsupervisor"

manta_ensure_zk

echo "Setting up marlin"
manta_setup_marlin

manta_common_setup_end

exit 0
