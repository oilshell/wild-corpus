#!/bin/bash

mkdir -p .ssh
cat bootstrap_chef.id_rsa.pub >> .ssh/authorized_keys
chown -R ubuntu:ubuntu .ssh
