#! /usr/bin/bash

## padding_kernel_gemmN.mlir line 6
config0="--operation conv2d_bwd_weight -t f16 -p=false -fil_layout=gkyxc -in_layout=nhwgc -out_layout=nhwgk -batchsize=64 -groupsize=1 -in_channels=3 -out_channels=64 -in_h=224 -in_w=224 -fil_h=7 -fil_w=7 --dilation_h=1 --dilation_w=1 --padding_h=3 --padding_w=3 --conv_stride_h=2 --conv_stride_w=2  -pv -rand 1 --rand_type float --x2"

## padding_kernel_gemmN.mlir line 1
## 15% failed but 20% passed
config1="--operation conv2d_bwd_weight -t f16 -p=false -fil_layout=gkcyx -in_layout=ngchw -out_layout=ngkhw -batchsize=64 -groupsize=1 -in_channels=3 -out_channels=64 -in_h=224 -in_w=224 -fil_h=7 -fil_w=7 --dilation_h=1 --dilation_w=1 --padding_h=3 --padding_w=3 --conv_stride_h=2 --conv_stride_w=2 -pv -rand 1 --rand_type float --x2"

## conv2d_host_validation_f16_bwd.mlir
## line 36 CHECK_ISSUE_127_18
## Under check-mlir-miopen: 20% failed 25% works
config2="--operation conv2d_bwd_weight -t f16 -fil_layout=kyxc -in_layout=nhwc -out_layout=nhwk -in_channels=256 -batchsize=64 -in_h=56 -in_w=56 -out_channels=64 -fil_h=3 -fil_w=3 -dilation_h=1 -dilation_w=1 -conv_stride_h=1 -conv_stride_w=1 -padding_h=1 -padding_w=1 -pv -rand 1 --rand_type float -x2"

## The following config failed in the nightly run 2022-07-12
## provided by Jungwood
config3="--operation conv2d -t f16 -p=false -fil_layout=gkyxc -in_layout=nhwgc -out_layout=nhwgk -batchsize=256 -groupsize=1 -in_channels=3 -out_channels=64 -in_h=230 -in_w=230 -fil_h=7 -fil_w=7 --dilation_h=1 --dilation_w=1 --padding_h=0 --padding_w=0 --conv_stride_h=2 --conv_stride_w=2 -pv -rand 1 --rand_type float --x2"

## MLIR408
## The following config should fail on MI200 but passes
## provided by Krzysztof
config4="--operation conv2d -t f16 --fil_layout kcyx --in_layout nchw --out_layout nkhw --batchsize 128 --in_channels 8 --in_h 8 --in_w 8 --out_channels 128 --fil_w 4 --fil_h 4 --dilation_h 1 --dilation_w 1 --conv_stride_h 1 --conv_stride_w 1 --padding_h 0 --padding_w 0 -p=false -x2"
