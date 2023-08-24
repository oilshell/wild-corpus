#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright (c) 2014, Joyent, Inc.
#

#
# bash environment file for working on Marlin
#

export PROTO="$PWD/build/proto/root/opt/smartdc/marlin"
export PATH="$PROTO/build/node/bin:$PROTO/sbin:$PROTO/tools:$PATH"
export PATH="$PROTO/node_modules/.bin:$PATH"
