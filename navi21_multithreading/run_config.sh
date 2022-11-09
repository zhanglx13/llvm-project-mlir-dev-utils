#! /bin/bash

ROCMLIR_DIR=/home/zhanglx/rocMLIR

## test/e2e/Resnet50/config
CONFIG="-batchsize=64 -in_channels=512 -in_h=7 -in_w=7 -out_channels=512 -fil_h=3 -fil_w=3 --dilation_h=1 --dilation_w=1 --conv_stride_h=1 --conv_stride_w=1 --padding_h=1 --padding_w=1 --operation conv2d_bwd_data -fil_layout=gkyxc -in_layout=nhwgc -out_layout=nhwgk -t f32  --arch gfx1030 -pv_with_gpu"

printf "Instance %02d: "  $1
${ROCMLIR_DIR}/build/bin/rocmlir-gen ${CONFIG} | ${ROCMLIR_DIR}/build/bin/rocmlir-driver -c | ${ROCMLIR_DIR}/build/external/llvm-project/llvm/bin/mlir-cpu-runner --shared-libs=/home/zhanglx/rocMLIR/build/external/llvm-project/llvm/lib/libmlir_rocm_runtime.so,/home/zhanglx/rocMLIR/build/lib/libconv-validation-wrappers.so,/home/zhanglx/rocMLIR/build/external/llvm-project/llvm/lib/libmlir_runner_utils.so --entry-point-result=void
