#!/bin/bash

for h in bcpc-{bootstrap,vm{1..3}} ; do
  VBoxManage startvm --type headless $h
done
