#! /bin/bash

## padding_kernel_gemmN.mlir
## line 6 CHECK_RESNET50_CONFIG4
config0="--operation conv2d_bwd_weight -t f16 -p=false -fil_layout=gkyxc -in_layout=nhwgc -out_layout=nhwgk -batchsize=64 -groupsize=1 -in_channels=3 -out_channels=64 -in_h=224 -in_w=224 -fil_h=7 -fil_w=7 --dilation_h=1 --dilation_w=1 --padding_h=3 --padding_w=3 --conv_stride_h=2 --conv_stride_w=2   -rand 1 --rand_type float --x2"

## padding_kernel_gemmN.mlir
## line 1 CHECK_RESNET50_CONFIG2
## CPU validation failed
config1="--operation conv2d_bwd_weight -t f16 -p=false -fil_layout=gkcyx -in_layout=ngchw -out_layout=ngkhw -batchsize=64 -groupsize=1 -in_channels=3 -out_channels=64 -in_h=224 -in_w=224 -fil_h=7 -fil_w=7 --dilation_h=1 --dilation_w=1 --padding_h=3 --padding_w=3 --conv_stride_h=2 --conv_stride_w=2 -rand 1 -x2 --rand_type float"

## conv2d_host_validation_f16_bwd.mlir
## line 2 CHECK_BWD_WEIGHT1
## CPU validation failed
config2="-rand 1  -x2 --rand_type float -fil_layout=kcyx -in_layout=nchw -out_layout=nkhw -batchsize=64 -in_channels=64 -out_channels=64 -in_h=7 -in_w=7 -fil_h=1 -fil_w=1 --dilation_h=1 --dilation_w=1 --padding_h=0 --padding_w=0 --conv_stride_h=1 --conv_stride_w=1 -p=false -t f16 --operation=conv2d_bwd_weight"

## padding_kernel_gemmK.mlir
## line 11 CHECK_RESNET50_F16_CONFIG1
## CPU validation failed
config3="--operation conv2d -t f16 -p=false -fil_layout=gkcyx -in_layout=ngchw -out_layout=ngkhw -batchsize=256 -groupsize=1 -in_channels=3 -out_channels=64 -in_h=224 -in_w=224 -fil_h=7 -fil_w=7 --dilation_h=1 --dilation_w=1 --padding_h=3 --padding_w=3 --conv_stride_h=2 --conv_stride_w=2 -rand 1  -x2 --rand_type float"

## conv2d_host_validation_f16_fwd.mlir
## line 2 CHECK_KYXC_NHWC_NHWK1
## CPU validation failed
config4="-rand 1  -x2 --rand_type float -fil_layout=kyxc -in_layout=nhwc -out_layout=nhwk -p -t f16"

## The following config failed in the nightly run 2022-07-12
## provided by Jungwood
config5="--operation conv2d -t f16 -p=false -fil_layout=gkyxc -in_layout=nhwgc -out_layout=nhwgk -batchsize=256 -groupsize=1 -in_channels=3 -out_channels=64 -in_h=230 -in_w=230 -fil_h=7 -fil_w=7 --dilation_h=1 --dilation_w=1 --padding_h=0 --padding_w=0 --conv_stride_h=2 --conv_stride_w=2  -rand 1 --rand_type float --x2"

## MLIR408
## The following config should fail on MI200 but passes
## provided by Krzysztof
config6="--operation conv2d -t f16 --fil_layout kcyx --in_layout nchw --out_layout nkhw --batchsize 128 --in_channels 8 --in_h 8 --in_w 8 --out_channels 128 --fil_w 4 --fil_h 4 --dilation_h 1 --dilation_w 1 --conv_stride_h 1 --conv_stride_w 1 --padding_h 0 --padding_w 0 -p=false -x2"


## conv2d_host_validation.mlir
## line 20 CHECK_RESNET101_NCHW_CONFIG2_WRW
## nightly-all 2022-07-14 Fixed e2e build
config7="--operation conv2d_bwd_weight -t f32 -p=false  -fil_layout=gkcyx -in_layout=ngchw -out_layout=ngkhw -batchsize=256 -groupsize=32 -in_channels=1024 -out_channels=1024 -in_h=7 -in_w=7 -fil_h=3 -fil_w=3 --dilation_h=1 --dilation_w=1 --padding_h=1 --padding_w=1 --conv_stride_h=1 --conv_stride_w=1 "
