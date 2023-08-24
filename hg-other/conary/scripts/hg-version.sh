#!/bin/sh
#
# Copyright (c) SAS Institute Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


hgDir=`dirname $0`/..
if [[ -x /usr/bin/hg && -d $hgDir/.hg ]] ; then
    rev=`hg id -i`
elif [ -f $hgDir/.hg_archival.txt ]; then
    rev=`grep node $hgDir/.hg_archival.txt |cut -d' ' -f 2 |head -c 12`;
else
    rev= ;
fi ;
echo "$rev"
