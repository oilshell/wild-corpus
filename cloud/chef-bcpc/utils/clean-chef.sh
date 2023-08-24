#!/bin/bash
hash -r

chef-server-ctl org-delete -y bcpc
chef-server-ctl user-delete -y admin
dpkg -r chef-server-core
