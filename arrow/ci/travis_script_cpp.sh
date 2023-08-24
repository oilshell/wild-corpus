#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

set -e

source $TRAVIS_BUILD_DIR/ci/travis_env_common.sh

# Check licenses according to Apache policy
git archive HEAD --prefix=apache-arrow/ --output=arrow-src.tar.gz
./dev/release/run-rat.sh arrow-src.tar.gz

pushd $CPP_BUILD_DIR

# ARROW-209: checks depending on the LLVM toolchain are disabled temporarily
# until we are able to install the full LLVM toolchain in Travis CI again

# if [ $TRAVIS_OS_NAME == "linux" ]; then
#   make check-format
#   make check-clang-tidy
# fi

ctest -VV -L unittest

popd
