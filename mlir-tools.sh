#! /bin/bash

## mlir tools
BUILD_DIR=~/rocMLIR/build
BIN_DIR=${BUILD_DIR}/bin
UP_BIN_DIR=${BUILD_DIR}/external/llvm-project/llvm/bin
LIB_MLIR_ROCM_RUNTIME=${BUILD_DIR}/external/llvm-project/llvm/lib/libmlir_rocm_runtime.so
LIB_CONV_VALID=${BUILD_DIR}/lib/libconv-validation-wrappers.so
LIB_MLIR_RUNNER_UTILS=${BUILD_DIR}/external/llvm-project/llvm/lib/libmlir_runner_utils.so
ROCMLIR_DRIVER="${BIN_DIR}/rocmlir-driver"
MLIR_ROCM_RUNNER="${BIN_DIR}/mlir-rocm-runner --shared-libs=${LIB_MLIR_ROCM_RUNTIME},${LIB_CONV_VALID},${LIB_MLIR_RUNNER_UTILS} --entry-point-result=void"
MLIR_CPU_RUNNER="${UP_BIN_DIR}/mlir-cpu-runner --shared-libs=${LIB_MLIR_ROCM_RUNTIME},${LIB_CONV_VALID},${LIB_MLIR_RUNNER_UTILS} --entry-point-result=void"
ROCMLIR_GEN="${BIN_DIR}/rocmlir-gen"
ROCMLIR_OPT="${BIN_DIR}/rocmlir-opt"
MLIR_OPT="${UP_BIN_DIR}/mlir-opt"
##
## To run rocm-runner manually:
## ./bin/mlir-miopen-driver -c | ./bin/mlir-rocm-runner --shared-libs=./external/llvm-project/llvm/lib/libmlir_rocm_runtime.so,./lib/libconv-validation-wrappers.so,./external/llvm-project/llvm/lib/libmlir_runner_utils.so --entry-point-result=void
