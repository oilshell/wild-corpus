#!/bin/bash

ENVIRONMENT=${1-Test-Laptop}

knife data bag show configs ${ENVIRONMENT} | grep cobbler-root-password:
knife bootstrap -E ${ENVIRONMENT} -r "role[BCPC-Headnode]" -x ubuntu --sudo 10.0.100.11
knife bootstrap -E ${ENVIRONMENT} -r "role[BCPC-Worknode]" -x ubuntu --sudo 10.0.100.12
knife bootstrap -E ${ENVIRONMENT} -r "role[BCPC-Worknode]" -x ubuntu --sudo 10.0.100.13
# if you have a separate mirror node:
# knife bootstrap -E ${ENVIRONMENT} -r "recipe[bcpc::apt-mirror],recipe[bcpc::apache-mirror]" -x ubuntu --sudo 10.0.100.4
