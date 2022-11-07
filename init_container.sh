#! /bin/bash

##
## $1: username:token
##

if [[ $# -lt 1 ]]; then
    echo "Need to provide credentials to download github repos"
    echo "./container_bringup.sh username:token"
    exit
fi

WORK_DIR=/home/zhanglx
CONTAINER=zhanglx-mlir-dev

## Download the script
docker exec --workdir ${WORK_DIR} ${CONTAINER} wget https://raw.githubusercontent.com/zhanglx13/llvm-project-mlir-dev-utils/main/container_bringup.sh
## Execute the script
docker exec --workdir ${WORK_DIR} ${CONTAINER} chmod +x container_bringup.sh
docker exec --workdir ${WORK_DIR} ${CONTAINER} ./container_bringup.sh $1
