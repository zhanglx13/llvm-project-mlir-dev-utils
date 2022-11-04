#! /bin/bash

## $1: run index
WORK_DIR=/home/zhanglx/rocMLIR/build
CONTAINER=zhanglx-mlir-dev
CMD="ninja check-rocmlir"
RESULT_DIR=nightly_random

## Clear the dmesg buffer
sudo dmesg -C
## Execute the command in the container
docker exec --workdir ${WORK_DIR} ${CONTAINER} ${CMD} | ts '[%H:%M:%S]' | tee -a ~/${RESULT_DIR}/lit_result$1.txt
## Obtain the dmesg
dmesg --kernel --ctime --userspace --decode > ~/${RESULT_DIR}/dmesg_log$1.txt
