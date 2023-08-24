#!/bin/bash -e

function gem_install {
    if ! gem list | grep -e "^$1 "; then
        sudo gem install $i --no-ri --no-rdoc
    fi
}

set -x
gem_install foodcritic
gem_install tailor

TOP=`git rev-parse --show-toplevel`
if [ ! -L "$TOP/.git/hooks/pre-commit" ]; then
    ln -s ../../tests/pre-commit "$TOP/.git/hooks/pre-commit"
fi
