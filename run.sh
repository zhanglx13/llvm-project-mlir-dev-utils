#! /bin/bash

## Usage
printUsage()
{
    echo "Later ..."
    echo "Usage: run.sh -i <inputFileName>|-g [options]"
    echo "Options:"
    echo "  -i <input mlir filename>"
    echo "  -g: call miopen-gen to generate the input"
    echo "      -n <index> choose the configs from config.sh (default: 0)"
    echo "      -b <validator> choose between cpu and gpu"
    echo "  Note: one of -i or -g must be specified!"
    echo "  -d: choose the rocm pipeline"
    echo "      If not set, choose the cpu pipeline"
    echo "  -l: In the rocm pipeline, generate the lowest IR before execution"
    echo "      use -o <lowestIRFilename> to secify the filename (default: lowest.mlir)"
    echo "      use -t <targetIRFunc> to specify the function IR to print (default: miopen)"
    echo "          targetIRFunc=all: print the whole file"
    echo "          targetIRFunc=0: print the wrapper function, which is the same as targetFunc=miopen"
    echo "  -r: invoke the runner tool to execute the IR (both pipeline)"
    echo "      -m <inputToRocmRunner> input filenmae to rocm-runner (default: driver_output.mlir)"
    echo "      -c <inputToCpuRunner> input filename to cpu-runner (default: opt_output.mlir)"
    echo "      -v: has verify function ==> print the last line"
    echo "         -e <f16Threshold> tolerance for fp16 datatype (default: 0.25)"
    echo "      -f: print the first line"
    echo "      if -v and -f are not specified, the whole result is printed"
}

## mlir tools
BUILD_DIR=/home/zhanglx/llvm-project-mlir/build
BIN_DIR=${BUILD_DIR}/bin
UP_BIN_DIR=${BUILD_DIR}/external/llvm-project/llvm/bin
LIB_MLIR_ROCM_RUNTIME=${BUILD_DIR}/external/llvm-project/llvm/lib/libmlir_rocm_runtime.so
LIB_CONV_VALID=${BUILD_DIR}/lib/libconv-validation-wrappers.so
LIB_MLIR_RUNNER_UTILS=${BUILD_DIR}/external/llvm-project/llvm/lib/libmlir_runner_utils.so
MLIR_MIOPEN_DRIVER="${BIN_DIR}/mlir-miopen-driver -c"
MLIR_ROCM_RUNNER="${BIN_DIR}/mlir-rocm-runner --shared-libs=${LIB_MLIR_ROCM_RUNTIME},${LIB_CONV_VALID},${LIB_MLIR_RUNNER_UTILS} --entry-point-result=void"
MLIR_CPU_RUNNER="${UP_BIN_DIR}/mlir-cpu-runner --shared-libs=${LIB_MLIR_ROCM_RUNTIME},${LIB_MLIR_RUNNER_UTILS} --entry-point-result=void"
MIOPEN_GEN="${BIN_DIR}/miopen-gen"
MIOPEN_OPT="${BIN_DIR}/miopen-opt"
MLIR_OPT="${UP_BIN_DIR}/mlir-opt"
##
## To run rocm-runner manually:
## ./bin/mlir-miopen-driver -c | ./bin/mlir-rocm-runner --shared-libs=./external/llvm-project/llvm/lib/libmlir_rocm_runtime.so,./lib/libconv-validation-wrappers.so,./external/llvm-project/llvm/lib/libmlir_runner_utils.so --entry-point-result=void

## lower the driver output to the lowest IR
## and extract the miopen_conv2d_xxx_0_gpu wrapper function
## $1: output IR generated by mlir-miopen-driver -c
## $2: function to be printed
##     <funcname>: print the IR of this function
##     all: print the IR of the whole file
##     0: print the wrapper function
## $3: output filename
print_lowestIR()
{
    ## run miopen-opt
    ## all these passes are from mlir-rocm-runner
    ${MIOPEN_OPT} \
        -convert-scf-to-cf \
        -gpu-kernel-outlining \
        -pass-pipeline='gpu.module(strip-debuginfo,convert-gpu-to-rocdl,gpu-to-hsaco{chip=gfx1030}),func.func(gpu-async-region,convert-math-to-llvm)' \
        -gpu-to-llvm \
        -async-to-async-runtime -convert-async-to-llvm \
        -convert-func-to-llvm \
        --llvm-software-bf16 \
        $1 &> lowest.mlir
    if [[ $2 == "0" ]]; then
        ## extract the kernel wrapper function
        echo "print lowest IR for miopen"
        sed '/llvm.func @miopen/,/}/!d;/}/q' lowest.mlir > $3
    elif [[ $2 == "all" ]]; then
        ## print the IR of the whole file
        echo "print lowest for $1"
        mv lowest.mlir $3
    else
        ## print the specified function
        echo "print lowest IR for func $2"
        func=$2
        sed "/llvm.func @$func/,/}/!d;/}/q" lowest.mlir > $3
    fi
}



OPTIND=1

run=0
lowestIR=0
lowestIRFilename="lowest.mlir"
inputToRocmRunner="driver_output.mlir"
inputToCpuRunner="opt_output.mlir"
hasVerify=0
validator=""
printFirst=0
callMiopenGen=0
driverPipeline=0
cpuPipeline=0
wrapper_func=0
targetIRFunc="miopen"
f16Threshold="0.25"
config_index=0
while getopts "hrlo:m:vc:gi:dwt:fe:n:b:" opt; do
    case "$opt" in
        h)
            printUsage
            exit 0
            ;;
        r)
            run=1
            ;;
        l)
            lowestIR=1
            ;;
        o)
            lowestIRFilename=$OPTARG
            ;;
        m)
            inputToRocmRunner=$OPTARG
            ;;
        v)
            hasVerify=1
            ;;
        c)
            inputToCpuRunner=$OPTARG
            ;;
        g)
            callMiopenGen=1
            ;;
        i)
            inputMLIR=$OPTARG
            ;;
        d)
            driverPipeline=1
            ;;
        b)
            if [[ $OPTARG = "gpu" ]];then
                validator="-pv_with_gpu"
            else
                validator="-pv"
            fi
            ;;
        w)
            wrapper_func=1
            ;;
        t)
            targetIRFunc=$OPTARG
            ;;
        f)
            printFirst=1
            ;;
        e)
            f16Threshold=$OPTARG
            ;;
        n)
            config_index=$OPTARG
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

source configs.sh

## Where to get the input mlir
##
if [[ $callMiopenGen -eq 1 ]]; then
    configName=config${config_index}
    MIOPEN_GEN_CMD=${!configName}
    DRIVER_INPUT="miopen-gen_result.mlir"
    echo "Generate input mlir from miopen-gen ${MIOPEN_GEN_CMD} $validator > ${DRIVER_INPUT}"
    ## no -prc, i.e. do not generate cpu kernel
    ## i.e. generate gpu kernel
    ${MIOPEN_GEN} -threshold=${f16Threshold} $validator ${MIOPEN_GEN_CMD} -o  ${DRIVER_INPUT}
else
    echo "Read input mlir from $inputMLIR"
    DRIVER_INPUT=$inputMLIR
fi

##
## Go through the miopen-driver -c pipeline
##
if [[ $driverPipeline -eq 1 ]]; then
    ## go through the driver
    printf "Running mlir-miopen-driver ${DRIVER_INPUT} > driver_output.mlir ... "
    ${MLIR_MIOPEN_DRIVER} ${DRIVER_INPUT} > driver_output.mlir
    echo " Done!!"
    ## get the lowest IR before execution
    if [[ $lowestIR -eq 1 ]]; then
        printf "Generate lowest IR for ${targetIRFunc} and written to ${lowestIRFilename}"
        print_lowestIR driver_output.mlir ${targetIRFunc} ${lowestIRFilename}
        echo " Done!!"
    fi
    ## Execute the generated IR
    if [[ $run -eq 1 ]]; then
        printf "Running mlir-rocm-runner ${inputToRocmRunner} > tmp_result ... "
        ${MLIR_ROCM_RUNNER} $inputToRocmRunner > tmp_result
        echo " Done!!"
        ## process result according to whether there is a verify function
        if [[ $hasVerify -eq 1 ]]; then
            result=$(tail -1 tmp_result)
            num=${result:1:1}
            msg="Pass!!"
            if [[ $num == "0" ]]; then
                msg="Fail!!"
            fi
            echo "$msg (threshold=${f16Threshold})"
        elif [[ $printFirst -eq 1 ]]; then
            result=$(head -1 tmp_result)
            echo "First line of output: $result"
        else
            echo "Output:"
            cat tmp_result
        fi
        #rm -f tmp_result
    fi
else
    ##
    ## go through the cpu pipeline
    ##
    printf "Running mlir-opt ..."
    ${MLIR_OPT} -pass-pipeline='gpu.module(strip-debuginfo,convert-gpu-to-rocdl{index-bitwidth=32 runtime=HIP},gpu-to-hsaco{chip=%chip})' > opt_output.mlir
    echo " Done!!"
    if [[ $run -eq 1 ]]; then
        printf "Running mlir-cpu-runner $inputToCpuRunner ... "
        ${MLIR_CPU_RUNNER} $inputToCpuRunner
        echo " Done!!"
    fi
fi

exit

## batch testing miopen-gen against configs from resnet50
config="fwd_f16"
config_file="/home/zhanglx/llvm-project-mlir/build/miopen-gen_configs/miopen-gen_config_$config"
i=1
echo "testing with $config"
while IFS= read -r line
do
    ${MIOPEN_GEN} -pv ${line} | ${MLIR_MIOPEN_DRIVER_CMD} | ${MLIR_ROCM_RUNNER_CMD} > tmp_result
    result=$(tail -1 tmp_result)
    echo "$i: $result"
    ((i++))
done < "${config_file}"
