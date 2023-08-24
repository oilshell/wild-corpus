#!/usr/bin/env bash
#
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

set -ex

HERE=$(cd `dirname "${BASH_SOURCE[0]:-$0}"` && pwd)

source $HERE/../set_env_common.sh
source $HERE/../setup_toolchain.sh
source $HERE/../functions.sh

git clone https://github.com/apache/arrow.git $ARROW_CHECKOUT

use_clang

bootstrap_python_env 3.6

build_arrow
build_parquet

build_pyarrow

$ARROW_CPP_BUILD_DIR/debug/io-hdfs-test

python -m pytest -vv -r sxX -s $PYARROW_PATH --parquet --hdfs
