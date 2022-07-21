#! /bin/bash

## Usage
printUsage()
{
    echo "Usage: run.sh <input options> <runner options> <lowering options>"
    echo "Input Options: (default: -g -n 0 -b cpu)"
    echo "  -i: <input mlir filename>"
    echo "  -g: call miopen-gen to generate the input"
    echo "      -n <index> choose the configs from config.sh (default: 0)"
    echo "      -b <validator> choose between cpu and gpu (default: cpu)"
    echo "Runner Options:"
    echo "  -d <runner>: choose between rocm and cpu pipeline"
    echo "  -r: invoke the runner tool to execute the IR (both pipeline)"
    echo "      Input to runner:"
    echo "        -m <inputToRocmRunner> input filename to rocm-runner (default: driver_output.mlir)"
    echo "        -c <inputToCpuRunner> input filename to cpu-runner (default: opt_output.mlir)"
    echo "      Print options:"
    echo "        -v: has verify function ==> print the last line"
    echo "            -e <f16Threshold> tolerance for fp16 datatype (default: 0.25)"
    echo "        -f: print the first line"
    echo "        if -v and -f are not specified, the whole result is printed"
    echo "Lowering Options:"
    echo "  -l: In the rocm pipeline, generate the lowest IR before execution"
    echo "      use -o <lowestIRFilename> to secify the filename (default: lowest.mlir)"
    echo "      use -t <targetIRFunc> to specify the function IR to print (default: miopen)"
    echo "          targetIRFunc=all: print the whole file"
    echo "          targetIRFunc=0: print the wrapper function, which is the same as targetFunc=miopen"
    echo "  -s: generate intermediate IR of each lowering step and put the results in lowering_IR/"
}

source mlir-tools.sh

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
validator="-pv"
printFirst=0
callMiopenGen=1
driverPipeline=2
wrapper_func=0
targetIRFunc="miopen"
f16Threshold="0.25"
config_index=0
print_lowering_step=0
while getopts "hrlo:m:vc:gi:d:wt:fe:n:b:s" opt; do
    case "$opt" in
        h)
            printUsage
            exit 0
            ;;
        b)
            if [[ $OPTARG == "gpu" ]];then
                validator="-pv_with_gpu"
            fi
            ;;
        c)
            inputToCpuRunner=$OPTARG
            ;;
        d)
            if [[ $OPTARG == "cpu" ]];then
                driverPipeline=0
            elif [[ $OPTARG == "rocm" ]];then
                driverPipeline=1
            else
                echo "Unrecognized pipeline: -d $OPTARG"
                echo "Choose either -d cpu or -d rocm"
                exit 0
            fi
            ;;
        e)
            f16Threshold=$OPTARG
            ;;
        f)
            printFirst=1
            ;;
        g)
            callMiopenGen=1
            ;;
        i)
            inputMLIR=$OPTARG
            callMiopenGen=0
            ;;
        l)
            lowestIR=1
            ;;
        m)
            inputToRocmRunner=$OPTARG
            ;;
        n)
            config_index=$OPTARG
            ;;
        o)
            lowestIRFilename=$OPTARG
            ;;
        r)
            run=1
            ;;
        s)
            print_lowering_step=1
            ;;
        t)
            targetIRFunc=$OPTARG
            ;;
        v)
            hasVerify=1
            ;;
        w)
            wrapper_func=1
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
## Print the result of each lowering step
## Following the commands in sanity_xdlops.mlir
##
if [[ ${print_lowering_step} -eq 1 ]]; then
    LOWERING_DIR=./lowering_IR
    ${MLIR_MIOPEN_DRIVER} -miopen-affix-params ${DRIVER_INPUT} > ${LOWERING_DIR}/0-affix-params.mlir
    ${MLIR_MIOPEN_DRIVER} -miopen-affix-params -miopen-conv-to-gemm ${DRIVER_INPUT} > ${LOWERING_DIR}/1-conv-to-gemm.mlir
    ${MLIR_MIOPEN_DRIVER} -miopen-affix-params -miopen-conv-to-gemm -miopen-gridwise-gemm-to-blockwise ${DRIVER_INPUT} > ${LOWERING_DIR}/2-blockwise.mlir
    ${MLIR_MIOPEN_DRIVER} -miopen-affix-params -miopen-conv-to-gemm -miopen-gridwise-gemm-to-blockwise -miopen-blockwise-gemm-to-threadwise ${DRIVER_INPUT} > ${LOWERING_DIR}/3-threadwise.mlir
    ${MLIR_MIOPEN_DRIVER} -miopen-affix-params -miopen-conv-to-gemm -miopen-gridwise-gemm-to-blockwise -miopen-blockwise-gemm-to-threadwise -miopen-threadwise-gemm-lowering ${DRIVER_INPUT} > ${LOWERING_DIR}/4-gemm-lowering.mlir
    ${MLIR_MIOPEN_DRIVER} -miopen-affix-params -miopen-conv-to-gemm -miopen-gridwise-gemm-to-blockwise -miopen-blockwise-gemm-to-threadwise -miopen-threadwise-gemm-lowering -miopen-sugar-to-loops ${DRIVER_INPUT} > ${LOWERING_DIR}/5-sugar-to-loops.mlir
    ${MLIR_MIOPEN_DRIVER} -miopen-affix-params -miopen-conv-to-gemm -miopen-gridwise-gemm-to-blockwise -miopen-blockwise-gemm-to-threadwise -miopen-threadwise-gemm-lowering -miopen-sugar-to-loops -miopen-loops-to-cf ${DRIVER_INPUT} > ${LOWERING_DIR}/6-loops-to-cf.mlir
    ${MLIR_MIOPEN_DRIVER} -miopen-affix-params -miopen-conv-to-gemm -miopen-gridwise-gemm-to-blockwise -miopen-blockwise-gemm-to-threadwise -miopen-threadwise-gemm-lowering -miopen-sugar-to-loops -miopen-loops-to-cf -convert-miopen-to-gpu ${DRIVER_INPUT} > ${LOWERING_DIR}/7-miopen-to-gpu.mlir
fi

##
## Go through the miopen-driver -c pipeline
##
if [[ $driverPipeline -eq 1 ]]; then
    ## go through the driver
    printf "Running mlir-miopen-driver ${DRIVER_INPUT} > driver_output.mlir ... "
    ${MLIR_MIOPEN_DRIVER} -c ${DRIVER_INPUT} > driver_output.mlir
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
elif [[ $driverPipeline -eq 0 ]]; then
    ##
    ## go through the cpu pipeline
    ##
    printf "Running mlir-opt ..."
    ${MLIR_OPT} -pass-pipeline='gpu.module(strip-debuginfo,convert-gpu-to-rocdl{index-bitwidth=32 runtime=HIP},gpu-to-hsaco{chip=gfx90a})' ${DRIVER_INPUT}> opt_output.mlir
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
