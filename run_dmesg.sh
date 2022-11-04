#! /bin/bash

## $1: run index
WORK_DIR=/home/zhanglx/rocMLIR/build
CONTAINER=zhanglx-mlir-dev
CMD="ninja check-rocmlir"
RESULT_DIR=nightly_random

for n in a b
do
    echo "-------------------------------------------------"
    echo "Start run $n"
    echo "-------------------------------------------------"
    ## Clear the dmesg buffer
    sudo dmesg -C
    ## Start the container
    docker container start ${CONTAINER}
    ## Execute the command in the container
    docker exec --workdir ${WORK_DIR} ${CONTAINER} ${CMD} | ts '[%H:%M:%S]' | tee -a ~/${RESULT_DIR}/lit_result$n.txt
    ## Obtain the dmesg
    dmesg --kernel --ctime --userspace --decode > ~/${RESULT_DIR}/dmesg_log$n.txt
    ## Stop the container
    docker container stop ${CONTAINER}
    sleep 5
done
