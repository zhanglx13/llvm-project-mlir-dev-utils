#! /bin/bash

##
## Given a folder of unit tests, this script executes all tests
## and collect their outputs to form a report
##
TEST_DIR=/home/zhanglx/llvm-project-mlir/mlir/test_debug/debug_test
XDLOPS="-x2"
VALIDATOR="-pv"
RANDINPUT="-rand 1"

source mlir-tools.sh

##
## $1: string
## $2: substring
##
## Check if $1 contains $2, if so, return 1, otherwiese, return 0
containsSubStr()
{
    if [[ "$1" == *"$2"* ]];then
        echo "1"
    else
        echo "0"
    fi
}

##
## $1: config to be processed
##
processConfig()
{
    config=$1
    isRand=$(containsSubStr "$config" "-rand ")
    isRandType=$(containsSubStr "$config" "-rand_type")
    ## remove all %option from config
    config=${config//%random_data/}
    config=${config//%xdlops/}
    config=${config//%pv/}
    config=${config//-pv/}
    ## Add -rand 1 if not included
    if [[ $isRand == "0" ]];then
        config="$config -rand 1"
    fi
    ## Add -rand_type float is not included
    if [[ $isRandType == "0" ]];then
        config="$config -rand_type float"
    fi
    ## Add xdlops
    config="$config $XDLOPS"
    ## Add VALIDATOR
    config="$config $VALIDATOR"
    echo "$config"
}

##
## $1: config to be processed
##
## This script process the input config and output its tags
## [isRand isRandOption isXdlops isXdlopsOption isPv isPvOption]
getConfigTags()
{
    config=$1
    isRand=$(containsSubStr "$config" "-rand ")
    isRandType=$(containsSubStr "$config" "-rand_type")
    isRandOption=$(containsSubStr "$config" "%random_data")
    isXdlops=$(containsSubStr "$config" "-x2")
    isXdlopsOption=$(containsSubStr "$config" "%xdlops")
    isPv=$(containsSubStr "$config" "-pv")
    isPvOption=$(containsSubStr "$config" "%pv")
    direction="fwd"
    if [[ "$config" == *"conv2d_bwd_weight"* ]];then
        direction="bwd_weight"
    elif [[ "$config" == *"conv2d_bwd_data"* ]];then
        direction="bwd_data"
    fi
    echo "$isRand $isRandOption $isRandType $isXdlops $isXdlopsOption $isPv $isPvOption $direction"
}

#rm  batch_configs.txt
cnt=0
for unittest in ${TEST_DIR}/*
do
    ## obtain the name of the test
    testFileName=${unittest%.mlir}
    testFileName=${testFileName##*/}
    ## prepare the config
    testCMD=$(sed -n "/\/\/ RUN:/p" $unittest)
    config=${testCMD%%|*}
    config=${config#*miopen-gen}
    ## get the tags first
    tags=$(getConfigTags "$config")
    config=$(processConfig "$config")
    #echo "$testFileName ==> $config" >> batch_configs.txt
    ## Invoke miopen-gen and execute the result
    verifyResult=$(${MIOPEN_GEN} $config | ${MLIR_MIOPEN_DRIVER} -c | ${MLIR_ROCM_RUNNER} | tail -1)
    echo "$verifyResult $tags $testFileName"
    #getConfigTags "$config"
    ((cnt++))
done
echo $cnt
#echo "${TEST_DIR}"








exit 0

##
## Old batch_run.sh deprecated
##
##
## $1: validator: cpu or gpu
## $2: result filename
##

result_filename=$2
for config in 1 2 3 4
do
    echo "Running config $config ..." | tee -a ${result_filename}
    for thr in 0.25 0.2 0.15 0.1 0.05 0.01 0.001
    do
        for i in  $(seq 0 1 9)
        do
            result=$(./run.sh -gdre $thr -v $1 -n $config | tail -1)
            echo "  $i ==> $result" | tee -a ${result_filename}
        done
    done
done
