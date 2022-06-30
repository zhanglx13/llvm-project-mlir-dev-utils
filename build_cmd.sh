#! /bin/bash

printUsage()
{
    echo "Usage: cmd_build.sh -b <options>|-m|-i"
    echo "  options:"
    echo "    0: PR_shared_library_build_and_fixed_tests"
    echo "-m: run ninja-check-mlir"
    echo "-i: run ninja-check-mlir-miopen"
    echo "-x: enable tests for xdlops"
}

##
## $1: enable xdlops or not (0: disable 1: enable)
##
PR_shared_library_build_and_fixed_tests()
{
    cmake -G Ninja -D CMAKE_BUILD_TYPE=RelWithDebInfo \
          -DMLIR_MIOPEN_DRIVER_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_PR_E2E_TEST_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_XDLOPS_TEST_ENABLED=$1 \
          -DMLIR_MIOPEN_DRIVER_E2E_TEST_ENABLED=0 \
          -DMLIR_MIOPEN_DRIVER_MISC_E2E_TEST_ENABLED=0 \
          -DMLIR_MIOPEN_DRIVER_TEST_GPU_VALIDATION=1 \
          -DLLVM_LIT_ARGS=-v \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
          ../
    ninja
}

PR_failed()
{
    cmake -G Ninja -D CMAKE_BUILD_TYPE=RelWithDebInfo \
          -DCMAKE_C_COMPILER=clang \
          -DCMAKE_CXX_COMPILER=clang++ \
          -DMLIR_MIOPEN_DRIVER_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_PR_E2E_TEST_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_XDLOPS_TEST_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_E2E_TEST_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_MISC_E2E_TEST_ENABLED=1 \
          -DMLIR_MIOPEN_DRIVER_TEST_GPU_VALIDATION=1 \
          -DLLVM_LIT_ARGS=-v \
          -DCMAKE_EXPORT_COMPILE_COMMANDS=1 \
          ../
    ninja
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


cd ~/llvm-project-mlir/
rm -rf build
mkdir build
cd build

case ${build_opt} in
    0)
        PR_shared_library_build_and_fixed_tests $xdlops
        ;;
    1)
        PR_failed
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
