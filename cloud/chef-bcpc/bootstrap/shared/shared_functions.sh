#!/bin/bash

# Uses Git to find the top level directory so that everything can be referenced
# via absolute paths.
REPO_ROOT=$(git rev-parse --show-toplevel)

if [[ $BOOTSTRAP_METHOD == "vagrant" ]]; then 
  do_on_node() {
    NODE=$1
    shift
    COMMAND="${*}"
    echo "EXECUTING on $NODE"
    vagrant ssh $NODE -c "$COMMAND"
  }
else
  # define it here with whatever we would use to SSH to Packer-booted machines
  :
fi

check_for_envvars() {
  FAILED_ENVVAR_CHECK=0
  REQUIRED_VARS="${@}"
  for ENVVAR in ${REQUIRED_VARS[@]}; do
    if [[ -z ${!ENVVAR} ]]; then
      echo "Environment variable $ENVVAR must be set!" >&2
      FAILED_ENVVAR_CHECK=1
    fi
  done
  if [[ $FAILED_ENVVAR_CHECK != 0 ]]; then exit 1; fi
}

load_configs(){
  # Source the bootstrap configuration defaults and overrides.
  # If the overrides file is at the previous expected location of bootstrap.sh,
  # move it and notify the user.
  if [[ -f "$REPO_ROOT/bootstrap/config/bootstrap_config.sh" ]]; then
    if [[ ! -f "$REPO_ROOT/bootstrap/config/bootstrap_config.sh.overrides" ]]; then
      echo "Performing one-time move of bootstrap_config.sh to bootstrap_config.sh.overrides..."
      mv $REPO_ROOT/bootstrap/config/bootstrap_config.sh $REPO_ROOT/bootstrap/config/bootstrap_config.sh.overrides
    else
      echo "ERROR: both bootstrap_config.sh and bootstrap_config.sh.overrides exist!" >&2
      echo "Please move all overrides to bootstrap_config.sh.overrides and remove bootstrap_config.sh!" >&2
      exit 1
    fi
  fi

  BOOTSTRAP_CONFIG_DEFAULTS="$REPO_ROOT/bootstrap/config/bootstrap_config.sh.defaults"
  BOOTSTRAP_CONFIG_OVERRIDES="$REPO_ROOT/bootstrap/config/bootstrap_config.sh.overrides"
  if [[ ! -f $BOOTSTRAP_CONFIG_DEFAULTS ]]; then
    echo "Bootstrap configuration defaults are missing! Your repository is corrupt; please restore $REPO_ROOT/bootstrap/config/bootstrap_config.sh.defaults." >&2
    exit 1
  fi
  source $BOOTSTRAP_CONFIG_DEFAULTS
  if [[ -f $BOOTSTRAP_CONFIG_OVERRIDES ]]; then source $BOOTSTRAP_CONFIG_OVERRIDES; fi
}
