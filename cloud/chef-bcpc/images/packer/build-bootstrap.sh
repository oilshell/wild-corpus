#!/bin/bash
KEYFILE="bootstrap_chef.id_rsa"
rm ${KEYFILE}*
ssh-keygen -N "" -f $KEYFILE
cp ${KEYFILE}.pub files
cp ${KEYFILE} ../..
packer build bcpc-bootstrap.json
