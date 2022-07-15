#! /bin/bash

printUsage()
{
    echo "Usage: cmd_build.sh -b <options>|-m|-i"
    echo "  options:"
    echo "    0: PR_shared_library_build_and_fixed_tests"
    echo "    1: enable all tests"
    echo "    2: build static library libMLIRMIOpen"
    echo "    3: build MIOpen with libMLIRMIOpen"
    echo "    4: test MIOpen configs"
    echo "    5: shared library and random tests"
    echo "    6: shared library and fixed tests"
    echo "-m: run ninja-check-mlir"
    echo "-i: run ninja-check-mlir-miopen"
    echo "-x: enable xdlops"
}

##
## $1: enable xdlops or not (0: disable 1: enable)
##
PR_shared_library_build_and_fixed_tests()
{
    cd ~/llvm-project-mlir/
    rm -f build/CMakeCache.txt
    cmake -G Ninja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo \
          -DMLIR_MIOPEN_DRIVER_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_PR_E2E_TEST_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_XDLOPS_TEST_ENABLED=$1 \
          -DMLIR_MIOPEN_DRIVER_E2E_TEST_ENABLED=0 \
          -DMLIR_MIOPEN_DRIVER_MISC_E2E_TEST_ENABLED=0 \
          -DMLIR_MIOPEN_DRIVER_TEST_GPU_VALIDATION=1 \
          -DLLVM_LIT_ARGS=-v \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
          ../
    cd build
    ninja
}

##
## $1: enable xdlops or not (0: disable 1: enable)
##
PR_enable_all()
{
    cd ~/llvm-project-mlir/
    rm -f build/CMakeCache.txt
    cmake -G Ninja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo \
          -DMLIR_MIOPEN_DRIVER_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_PR_E2E_TEST_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_XDLOPS_TEST_ENABLED=$1 \
          -DMLIR_MIOPEN_DRIVER_E2E_TEST_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_MISC_E2E_TEST_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_TEST_GPU_VALIDATION=1 \
          -DLLVM_LIT_ARGS=-v \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
          ../
    cd build
    ninja
}

##
## stage: Shared library build and random tests
## $1: xdlops
##
sharedLib_random()
{
    cd ~/llvm-project-mlir/
    rm -f build/CMakeCache.txt
    cmake . -G Ninja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo \
          -DMLIR_MIOPEN_DRIVER_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_PR_E2E_TEST_ENABLED=0 \
          -DMLIR_MIOPEN_DRIVER_XDLOPS_TEST_ENABLED=$1 \
          -DMLIR_MIOPEN_DRIVER_E2E_TEST_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_RANDOM_DATA_SEED=1 \
          -DMLIR_MIOPEN_DRIVER_MISC_E2E_TEST_ENABLED=0 \
          -DMLIR_MIOPEN_DRIVER_TEST_GPU_VALIDATION=0 \
          -DMLIR_MIOPEN_DRIVER_TIMING_TEST_ENABLED=1 \
          -DLLVM_LIT_ARGS=-v \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=1
    cd build
    ninja check-mlir-miopen
}

##
## stage: Shared library build and fixed tests
## $1: xdlops
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
         -DMLIR_MIOPEN_DRIVER_TEST_GPU_VALIDATION=1 \
         -DLLVM_LIT_ARGS=-v \
         -DCMAKE_EXPORT_COMPILE_COMMANDS=1
    cd build
    ninja check-mlir check-mlir-miopen
}

build_staticLib()
{
    ##
    ## build libMLIRMIOpen
    ##
    cd ~/llvm-project-mlir/
    #rm -f build/CMakeCache.txt
    cmake . -G Ninja -B build -DCMAKE_BUILD_TYPE=Release \
          -DMLIR_MIOPEN_DRIVER_ENABLED=1 \
          -DBUILD_FAT_LIBMLIRMIOPEN=ON
    cd build
    ninja libMLIRMIOpen
    cmake --install . --component libMLIRMIOpen --prefix ~/dummy/
}

build_MIOpen_with_MLIR()
{
    ##
    ## build MIOpen with libMLIRMIOpen
    ##
    cd ~/MIOpen
    #rm -f build/CMakeCache.txt
    cmake . -G "Unix Makefiles" -B build -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_CXX_COMPILER=/opt/rocm/llvm/bin/clang++ \
          -DCMAKE_C_COMPILER=/opt/rocm/llvm/bin/clang \
          -DMIOPEN_USE_MLIR=On \
          -DMIOPEN_BACKEND=HIP \
          -DCMAKE_PREFIX_PATH=~/dummy \
          "-DCMAKE_CXX_FLAGS=-isystem ~/dummy/include" \
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

build_opt=0
check_mlir=0
check_miopen=0
xdlops=0
while getopts "hxmib:" opt; do
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
        PR_shared_library_build_and_fixed_tests $xdlops
        ;;
    1)
        PR_enable_all $xdlops
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
        sharedLib_random $xdlops
        ;;
    6)
        sharedLib_fixed $xdlops
        ;;
    *)
        echo "unknown build option"
        ;;
esac

if [[ ${check_mlir} -eq 1 ]]; then
    ninja check-mlir
fi

if [[ ${check_miopen} -eq 1 ]]; then
    ninja check-mlir-miopen
fi
