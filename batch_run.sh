#! /bin/bash


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
## We remove any options, such as %random_data, %pv, and %xdlops
## and explicitly attach the following to the config:
## -rand 1            this allows us to control the random input
## -rand_type float   this is required since the defaut is int
## $XDLOPS            this allows us to control is -x2 is present
## $VALIDATOR         this allows us to control whether -pv or -pv_with_gpu
##                    should be used
processConfig()
{
    config=$1
    isRand=$(containsSubStr "$config" "-rand ")
    isRandType=$(containsSubStr "$config" "-rand_type")
    ## remove all %option from config
    config=${config//%random_data/}
    config=${config//%xdlops/}
    config=${config//-x2/}
    config=${config//--x2/}
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
## [isRand isRandOption isRandType isXdlops isXdlopsOption isPv isPvOption direction]
##
## Explanation of (isRand, isRandOption, isRandType):
## (0 0 0):
##   This test always sets the input using -rand fixed and -rand_type int
##   And this might explain why this test does not fail during check-mlir-miopen
## (0 1 1):
##   This is the most common case that %random_data is present to let us choose
##   how to initialize the input during CMake build
##   Also -rand_type float is set to generate float random numbers
## (1 0 0):
##   This test only has -rand 1 but generate integer random numbers
##   between [-5, 5] to initialize the inputs
## (0 1 0):
##   This test has an option %randm_data to set -rand but the random number
##   type is always integer
## (1 0 1):
##   This test always uses -rand 1 -rand_type float
##   It does not allow CMake to change how inputs are initialized
##
## Explanation of (isXdlops, isXdlopsOption)
## (0 0):
##   This test always disable xdlops
## (0 1)
##   This test has an option %xdlops
##
## Explanation of (isPv isPvOption)
## (0 1)
##   This test has an option %pv so that we can choose pv_with_gpu
## (1 0)
##   This test does not have an option to use pv_with_gpu
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

##
## $1: total number of tests
## $2: XDLOPS
## $3: VALIDATOR
## $4: RESULT_FILENAME
## %5: BATCH_CONFIG_FILENAME
batch_run()
{
    cnt=$1
    XDLOPS=$2
    VALIDATOR=$3
    RESULT_FILENAME=$4
    BATCH_CONFIG_FILENAME=$5
    echo "Running $cnt tests ... "
    echo "Writing results into ${RESULT_FILENAME}"

    i=1
    #rm -f ${RESULT_FILENAME}
    #rm -f ${BATCH_CONFIG_FILENAME}
    #rm batch_configs.txt
    for unittest in ${TEST_DIR}/*
    do
        ## obtain the name of the test
        testFileName=${unittest%.mlir}
        testFileName=${testFileName##*/}
        ## prepare the config
        testCMD=$(sed -n "/\/\/ RUN:/p" $unittest)
        config=${testCMD%%|*}
        config=${config#*miopen-gen}
        #echo "$testFileName $config" >> batch_configs.txt
        ## get the tags first
        tags=$(getConfigTags "$config")
        config=$(processConfig "$config")
        #echo "$testFileName ==> $config" >> ${BATCH_CONFIG_FILENAME}
        ## Invoke miopen-gen and execute the result
        verifyResult=$(${MIOPEN_GEN} $config | ${MLIR_MIOPEN_DRIVER} -c | ${MLIR_ROCM_RUNNER} | tail -1)
        echo "$verifyResult $tags $testFileName ($i of $cnt)" | tee -a ${RESULT_FILENAME}
        ((i++))
    done
}

##
## Given a folder of unit tests, this script executes all tests
## and collect their outputs to form a report
##
TEST_DIR=/home/zhanglx/llvm-project-mlir/mlir/test_debug/debug_test

cnt=0
for unittest in ${TEST_DIR}/*
do
    ((cnt++))
done

#RAND_RANGE="smallrand" # rand0 [-1, 1]
#RAND_RANGE="midrand"   # rand1 [-10, 10]
#RAND_RANGE="rand2"      # rand2 [-5, 5]
RAND_RANGE="rand3"      # rand2 [2, 7]

batch_run $cnt "-x2" "-pv"          "verify_f16_xdlops_pv_${RAND_RANGE}.txt"             "test_config.txt"

batch_run $cnt ""    "-pv"          "verify_f16_nonxdlops_pv_${RAND_RANGE}.txt"          "test_config.txt"

batch_run $cnt "-x2" "-pv_with_gpu" "verify_f16_xdlops_pv-with-gpu_${RAND_RANGE}.txt"    "test_config.txt"

batch_run $cnt ""    "-pv_with_gpu" "verify_f16_nonxdlops_pv-with-gpu_${RAND_RANGE}.txt" "test_config.txt"


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
