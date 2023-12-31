#
# Copyright 2017 Dell EMC.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# * Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# $FreeBSD: stable/11/usr.bin/sed/tests/sed2_test.sh 321208 2017-07-19 15:58:27Z ngie $
#

atf_test_case inplace_hardlink_src
inplace_hardlink_src_head()
{
	atf_set "descr" "Verify -i works with a symlinked source file"
}
inplace_hardlink_src_body()
{
	echo foo > a
	atf_check ln a b
	atf_check sed -i '' -e 's,foo,bar,g' b
	atf_check -o 'inline:bar\n' -s exit:0 cat b
}

atf_test_case inplace_symlink_src
inplace_symlink_src_head()
{
	atf_set "descr" "Verify -i works with a symlinked source file"
}
inplace_symlink_src_body()
{
	echo foo > a
	atf_check ln -s a b
	atf_check -e not-empty -s not-exit:0 sed -i '' -e 's,foo,bar,g' b
}

atf_init_test_cases()
{
	atf_add_test_case inplace_hardlink_src
	atf_add_test_case inplace_symlink_src
}
