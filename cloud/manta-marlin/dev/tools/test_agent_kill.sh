#!/bin/bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright (c) 2014, Joyent, Inc.
#

#
# test_agent_kill.sh: periodically kills the agent (used for stress testing).
#
while sleep $(( RANDOM % 30 + 270 )); do
	date
	svcadm restart marlin-agent
done
