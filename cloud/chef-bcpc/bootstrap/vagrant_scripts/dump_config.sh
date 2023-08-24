#!/bin/bash
# Simply dumps the config
hash -r

export PATH=/bin:/usr/bin
DIR="$( cd ${0%/*} && pwd -P )"
confdir="$(cd "$DIR/../config" &&  pwd -P)"

# Relocate and set me
defaults="$confdir/bootstrap_config.sh.defaults"
override="$confdir/bootstrap_config.sh.overrides"

env -i HOME="$HOME" /bin/bash -c \
    "export -n PWD SHLVL ; source $defaults && source $override && printenv | \
        sed -E '/^(_|HOME)=/d' | sort"
