#! /bin/bash

## $1: testsuite: fixed or random
if [[ $# -lt 1 ]]; then
    echo "Must specifiy fixed or random"
    exit 0
fi
WORK_DIR=/home/zhanglx/rocMLIR/build
CONTAINER=zhanglx-mlir-dev
CMD="ninja check-rocmlir"
RESULT_DIR=nightly_$1

echo "Start container"
docker container start ${CONTAINER}
## cmake configure and build for fixed nightly test
if [[ "$1" == "fixed" ]]; then
    echo "Config and build for nightly fixed tests"
    docker exec --workdir ${WORK_DIR} ${CONTAINER} cmake -G Ninja -D CMAKE_BUILD_TYPE=RelWithDebInfo -DROCMLIR_DRIVER_ENABLED=1 -DROCMLIR_DRIVER_PR_E2E_TEST_ENABLED=0 -DROCMLIR_DRIVER_E2E_TEST_ENABLED=1 -DROCK_E2E_TEST_ENABLED=1 -DROCMLIR_DRIVER_MISC_E2E_TEST_ENABLED=1 -DROCMLIR_DRIVER_TEST_GPU_VALIDATION=1 "-DLLVM_LIT_ARGS=-v --time-tests" -DCMAKE_EXPORT_COMPILE_COMMANDS=1 ..
fi

## cmake configure and build for random nightly test
if [[ "$1" == "random" ]]; then
    echo "Config and build for nightly random tests"
    docker exec --workdir ${WORK_DIR} ${CONTAINER} cmake -G Ninja -D CMAKE_BUILD_TYPE=RelWithDebInfo -DROCMLIR_DRIVER_ENABLED=1 -DROCMLIR_DRIVER_PR_E2E_TEST_ENABLED=0 -DROCMLIR_DRIVER_E2E_TEST_ENABLED=1 -DROCK_E2E_TEST_ENABLED=1 -DROCMLIR_DRIVER_RANDOM_DATA_SEED=1 -DROCMLIR_DRIVER_MISC_E2E_TEST_ENABLED=0 -DROCMLIR_DRIVER_TEST_GPU_VALIDATION=0 "-DLLVM_LIT_ARGS=-v --time-tests" -DCMAKE_EXPORT_COMPILE_COMMANDS=1 ..
fi
## Stop the container
echo "Stop container"
docker container stop ${CONTAINER}

for n in a b
do
    echo "-----------------------------------------------------------"
    echo "Start run $n"
    echo "-----------------------------------------------------------"
    ## Clear the dmesg buffer
    dmesg -C
    ## Start the container
    echo "Start container"
    docker container start ${CONTAINER}
    ## Execute the command in the container
    docker exec --workdir ${WORK_DIR} ${CONTAINER} ${CMD} | ts '[%H:%M:%S]' | tee -a ~/${RESULT_DIR}/lit_result$n.txt
    ## Obtain the dmesg
    dmesg --kernel --ctime --userspace --decode > ~/${RESULT_DIR}/dmesg_log$n.txt
    ## Stop the container
    echo "Stop container"
    docker container stop ${CONTAINER}
    sleep 5
done
