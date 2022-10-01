#! /bin/bash

printUsage()
{
    echo "Usage: cmd_build.sh -b <options>|-m|-i"
    echo "  options:"
    echo "    0: PR_shared_library_build_and_fixed_tests"
    echo "    1: enable all tests"
    echo "    2: build static library librockCompiler"
    echo "    3: build MIOpen with librockCompiler"
    echo "    4: test MIOpen configs"
    echo "    5: shared library and random tests"
    echo "    6: shared library and fixed tests"
    echo "    7: build export package for miopen and migraphx"
    echo "-m: run ninja-check-mlir"
    echo "-i: run ninja-check-mlir-miopen"
    echo "-x: enable xdlops"
    echo "-v <validator>: cpu or gpu validation"
    echo "   gpu validation is chosen only when validation=gpu"
    echo "-r <rand_seed>: choose how to initalize inputs randomly"
    echo "                0, 1, none, or fixed"
    echo "-e <target>: choose the exported target: miopen (default) or migraphx"
}

##
## $1: enable xdlops or not (0: disable 1: enable)
##
PR_shared_library_build_and_fixed_tests()
{
    cd ~/rocMLIR/
    rm -f build/CMakeCache.txt
    cmake -G Ninja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo \
          -DROCMLIR_DRIVER_ENABLED=1 \
          -DROCMLIR_DRIVER_PR_E2E_TEST_ENABLED=1 \
          -DROCMLIR_DRIVER_FORCE_MFMA=ON \
          -DROCMLIR_DRIVER_FORCE_DOT=ON \
          -DROCMLIR_DRIVER_FORCE_ATOMICADD=ON \
          -DROCMLIR_DRIVER_E2E_TEST_ENABLED=0 \
          -DROCK_E2E_TEST_ENABLED=0 \
          -DROCMLIR_DRIVER_MISC_E2E_TEST_ENABLED=0 \
          -DROCMLIR_DRIVER_TEST_GPU_VALIDATION=1 \
          "-DLLVM_LIT_ARGS=-v --time-tests" \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=1
    cd build
    ninja check-rocmlir
}

##
## $1: enable xdlops or not (0: disable 1: enable)
##
PR_enable_all()
{
    cd ~/rocMLIR/
    rm -f build/CMakeCache.txt
    cmake -G Ninja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo \
          -DROCMLIR_DRIVER_ENABLED=1 \
          -DROCMLIR_DRIVER_PR_E2E_TEST_ENABLED=1 \
          -DROCMLIR_DRIVER_FORCE_MFMA=ON \
          -DROCMLIR_DRIVER_FORCE_DOT=ON \
          -DROCMLIR_DRIVER_FORCE_ATOMICADD=ON \
          -DROCMLIR_DRIVER_E2E_TEST_ENABLED=1 \
          -DROCK_E2E_TEST_ENABLED=1 \
          -DROCMLIR_DRIVER_MISC_E2E_TEST_ENABLED=1 \
          -DROCMLIR_DRIVER_TEST_GPU_VALIDATION=1 \
          "-DLLVM_LIT_ARGS=-v --time-tests" \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=1
          ../
    cd build
    ninja check-rocmlir
}

##
## stage: Shared library build and random tests
## $1: xdlops
## $2: gpu validation
## $3: random seed: 0, 1, none, or fixed
##
sharedLib_random()
{
    cd ~/llvm-project-mlir/
    rm -f build/CMakeCache.txt
    cmake . -G Ninja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo \
          -DMLIR_MIOPEN_DRIVER_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_PR_E2E_TEST_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_XDLOPS_TEST_ENABLED=$1 \
          -DMLIR_MIOPEN_DRIVER_E2E_TEST_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_RANDOM_DATA_SEED=$3 \
          -DMLIR_MIOPEN_DRIVER_MISC_E2E_TEST_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_TEST_GPU_VALIDATION=$2 \
          -DMLIR_MIOPEN_DRIVER_TIMING_TEST_ENABLED=1 \
          -DLLVM_LIT_ARGS=-v \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=1
    cd build
    ninja check-mlir-miopen
}

##
## stage: Shared library build and fixed tests
## $1: xdlops
## $2: gpu validation
##
sharedLib_fixed()
{
    cd ~/llvm-project-mlir/
    rm -f build/CMakeCache.txt
    make . -G Ninja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo \
         -DMLIR_MIOPEN_DRIVER_ENABLED=1 \
         -DMLIR_MIOPEN_DRIVER_PR_E2E_TEST_ENABLED=0 \
         -DMLIR_MIOPEN_DRIVER_XDLOPS_TEST_ENABLED=$1 \
         -DMLIR_MIOPEN_DRIVER_E2E_TEST_ENABLED=1 \
         -DMLIR_MIOPEN_DRIVER_MISC_E2E_TEST_ENABLED=1 \
         -DMLIR_MIOPEN_DRIVER_TEST_GPU_VALIDATION=$2 \
         -DLLVM_LIT_ARGS=-v \
         -DCMAKE_EXPORT_COMPILE_COMMANDS=1
    cd build
    ninja check-mlir check-mlir-miopen
}

build_staticLib()
{
    ##
    ## build librockCompiler
    ##
    cd ~/llvm-project-mlir/
    #rm -f build/CMakeCache.txt
    cmake . -G Ninja -B build -DCMAKE_BUILD_TYPE=Release \
          -DMLIR_MIOPEN_DRIVER_ENABLED=1 \
          -DBUILD_FAT_LIBROCKCOMPILER=ON
    cd build
    ninja librockCompiler
    cmake --install . --component librockCompiler --prefix ~/dummy/
}

build_export_package()
{
    ## $1: target: miopen or migraphx
    if [[ "$1" == "miopen" ]]; then
        TARGET=BUILD_FAT_LIBROCKCOMPILER
    elif [[ "$1" == "migraphx" ]]; then
        TARGET=BUILD_MIXR_TARGET
    else
        echo "Unknown target: $1"
        exit
    fi
    ##
    ## build librockCompiler
    ##
    cd ~/rocMLIR/
    #rm -f build/CMakeCache.txt
    cmake . -G Ninja -B build \
          -D${TARGET}=ON
    cd build
    ninja
    sudo cmake --install . --prefix /usr/local
}

build_MIOpen_with_MLIR()
{
    ##
    ## build MIOpen with librockCompiler
    ##
    cd ~/MIOpen
    #rm -f build/CMakeCache.txt
    cmake . -G "Unix Makefiles" -B build -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_CXX_COMPILER=/opt/rocm/llvm/bin/clang++ \
          -DCMAKE_C_COMPILER=/opt/rocm/llvm/bin/clang \
          -DMIOPEN_USE_MLIR=On \
          -DMIOPEN_BACKEND=HIP \
          -DCMAKE_PREFIX_PATH=/usr/local \
          "-DCMAKE_CXX_FLAGS=-isystem /usr/local/include" \
          -DMIOPEN_USER_DB_PATH=~/MIOpen/build/MIOpenUserDB \
          "-DMIOPEN_TEST_FLAGS=--verbose --disable-verification-cache"
    cd build
    make -j $(nproc) MIOpenDriver
}


test_MIOpen_configs()
{
    ##
    ## Test MIOpen config
    ##
    MIOPEN_TEST_DIR=~/llvm-project-mlir/mlir/utils/jenkins/miopen-tests/
    # copy artifacts
    cp -r /data/MIOpenUserDB/ ~/MIOpen/build/
    ${MIOPEN_TEST_DIR}/miopen_validate.sh --layout NCHW --direction 1 --dtype fp16 --no-tuning < ${MIOPEN_TEST_DIR}/resnet50-miopen-configs
    ${MIOPEN_TEST_DIR}/miopen_validate.sh --layout NCHW --direction 2 --dtype fp16 --no-tuning < ${MIOPEN_TEST_DIR}/resnet50-miopen-configs
    ${MIOPEN_TEST_DIR}/miopen_validate.sh --layout NCHW --direction 4 --dtype fp16 --no-tuning < ${MIOPEN_TEST_DIR}/resnet50-miopen-configs

    rm -r ~/MIOpen/build/MIOpenUserDB
    ${MIOPEN_TEST_DIR}/miopen_validate.sh --layout NCHW --direction 1 --dtype fp16 --no-tuning < ${MIOPEN_TEST_DIR}/resnet50-miopen-configs
    ${MIOPEN_TEST_DIR}/miopen_validate.sh --layout NCHW --direction 2 --dtype fp16 --no-tuning < ${MIOPEN_TEST_DIR}/resnet50-miopen-configs
    ${MIOPEN_TEST_DIR}/miopen_validate.sh --layout NCHW --direction 4 --dtype fp16 --no-tuning < ${MIOPEN_TEST_DIR}/resnet50-miopen-configs
}



OPTIND=1

build_opt=1000
check_mlir=0
check_miopen=0
xdlops=0
gpu_validation=0
rand_seed=1
TARGET=miopen
while getopts "hxmib:v:r:e:" opt; do
    case "$opt" in
        h)
            printUsage
            exit 0
            ;;
        m)
            check_mlir=1
            ;;
        i)
            check_miopen=1
            ;;
        b)
            build_opt=$OPTARG
            ;;
        x)
            xdlops=1
            ;;
        v)
            if [[ $OPTARG == "gpu" ]];then
                gpu_validation=1
            fi
            ;;
        r)
            rand_seed=$OPTARG
            ;;
        e)
            TARGET=$OPTARG
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


#cd ~/llvm-project-mlir/
#rm -rf build
#mkdir build
#cd build

case ${build_opt} in
    0)
        PR_shared_library_build_and_fixed_tests
        ;;
    1)
        PR_enable_all
        ;;
    2)
        build_staticLib
        ;;
    3)
        build_MIOpen_with_MLIR
        ;;
    4)
        test_MIOpen_configs
        ;;
    5)
        sharedLib_random $xdlops ${gpu_validation} ${rand_seed}
        ;;
    6)
        sharedLib_fixed $xdlops ${gpu_validation}
        ;;
    7)
        build_export_package $TARGET
        ;;
    *)
        echo "unknown build option $OPTARG"
        ;;
esac

cd ~/rocMLIR/build
if [[ ${check_mlir} -eq 1 ]]; then
    ninja check-mlir
fi

if [[ ${check_miopen} -eq 1 ]]; then
    ninja check-mlir-miopen
fi
