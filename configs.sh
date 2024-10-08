#! /bin/bash

###############################
## padding_kernel_gemmN.mlir ##
###############################

## line 1 CHECK_RESNET50_CONFIG2
## CPU validation failed
config1="--operation conv2d_bwd_weight -t f32 -p=false -fil_layout=gkcyx -in_layout=ngchw -out_layout=ngkhw -batchsize=64 -groupsize=1 -in_channels=3 -out_channels=64 -in_h=224 -in_w=224 -fil_h=7 -fil_w=7 --dilation_h=1 --dilation_w=1 --padding_h=3 --padding_w=3 --conv_stride_h=2 --conv_stride_w=2 -rand 1 -x2 --rand_type float"

## line 6 CHECK_RESNET50_CONFIG4
## CPU validation failed
## When inputs are initialized with all 2.0,
config0="--operation conv2d_bwd_weight -t f16 -p=false -fil_layout=gkyxc -in_layout=nhwgc -out_layout=nhwgk -batchsize=64 -groupsize=1 -in_channels=3 -out_channels=64 -in_h=224 -in_w=224 -fil_h=7 -fil_w=7 --dilation_h=1 --dilation_w=1 --padding_h=3 --padding_w=3 --conv_stride_h=2 --conv_stride_w=2   -rand 1 --rand_type float --x2"


###############################
## padding_kernel_gemmK.mlir ##
###############################

## line 11 CHECK_RESNET50_F16_CONFIG1
## CPU validation failed
config3="--operation conv2d -t f16 -p=false -fil_layout=gkcyx -in_layout=ngchw -out_layout=ngkhw -batchsize=1 -groupsize=1 -in_channels=3 -out_channels=64 -in_h=224 -in_w=224 -fil_h=7 -fil_w=7 --dilation_h=1 --dilation_w=1 --padding_h=3 --padding_w=3 --conv_stride_h=2 --conv_stride_w=2 -rand 1  -x2 --rand_type float"

## line 16 CHECK_RESNET50_F16_CONFIG2
## CPU failed
config6="--operation conv2d -t f16 -p=false -fil_layout=gkcyx -in_layout=ngchw -out_layout=ngkhw -batchsize=256 -groupsize=1 -in_channels=3 -out_channels=64 -in_h=230 -in_w=230 -fil_h=7 -fil_w=7 --dilation_h=1 --dilation_w=1 --padding_h=0 --padding_w=0 --conv_stride_h=2 --conv_stride_w=2 -rand 1  -x2 --rand_type float"

## line 21 CHECK_RESNET50_F16_CONFIG4
config10="--operation conv2d -t f16 -p=false -fil_layout=gkyxc -in_layout=nhwgc -out_layout=nhwgk -batchsize=256 -groupsize=1 -in_channels=3 -out_channels=64 -in_h=230 -in_w=230 -fil_h=7 -fil_w=7 --dilation_h=1 --dilation_w=1 --padding_h=0 --padding_w=0 --conv_stride_h=2 --conv_stride_w=2 -rand 1  -x2 --rand_type float"

#########################################
## conv2d_host_validation_f16_bwd.mlir ##
#########################################

## line 2 CHECK_BWD_WEIGHT1
## CPU validation failed
config2="-rand 1  -x2 --rand_type float -fil_layout=kcyx -in_layout=nchw -out_layout=nkhw -batchsize=64 -in_channels=64 -out_channels=64 -in_h=7 -in_w=7 -fil_h=1 -fil_w=1 --dilation_h=1 --dilation_w=1 --padding_h=0 --padding_w=0 --conv_stride_h=1 --conv_stride_w=1 -p=false -t f16 --operation=conv2d_bwd_weight"

## line 8 CHECK_BWD_DATA1
## CPU failed
config7="-rand 1 -x2 --rand_type float -fil_layout=kcyx -in_layout=nchw -out_layout=nkhw -batchsize=256 -in_channels=64 -out_channels=64 -in_h=7 -in_w=7 -fil_h=1 -fil_w=1 --dilation_h=1 --dilation_w=1 --padding_h=0 --padding_w=0 --conv_stride_h=1 --conv_stride_w=1 -p=false -t f16 --operation=conv2d_bwd_data"

## line 14 CHECK_ISSUE_127_6
## CPU failed
config8="-rand 1 -x2 --rand_type float --operation conv2d_bwd_weight -t f16 --fil_layout kyxc --in_layout nhwc --out_layout nhwk --batchsize 64 --in_channels 1024 --in_h 14 --in_w 14 --out_channels 2048 --fil_w 1 --fil_h 1 --dilation_h 1 --dilation_w 1 --conv_stride_h 2 --conv_stride_w 2 --padding_h 0 --padding_w 0 "

## line 15 CHECK_ISSUE_127_7
config12="-rand 1 -x2 --rand_type float --operation conv2d_bwd_weight -t f16 --fil_layout kyxc --in_layout nhwc --out_layout nhwk --batchsize 64 --in_channels 1024 --in_h 14 --in_w 14 --out_channels 256 --fil_w 1 --fil_h 1 --dilation_h 1 --dilation_w 1 --conv_stride_h 1 --conv_stride_w 1 --padding_h 0 --padding_w 0"

# line 35 CHECK_ISSUE_127_17
config14="-rand 1 -x2 --rand_type float --operation conv2d_bwd_weight -t f16 -fil_layout=kyxc -in_layout=nhwc -out_layout=nhwk -in_channels=256 -batchsize=128 -in_h=7 -in_w=7 -out_channels=512 -fil_h=3 -fil_w=3 -dilation_h=1 -dilation_w=1 -conv_stride_h=1 -conv_stride_w=1 -padding_h=1 -padding_w=1"

# line 54 CHECK_ISSUE_71_4
config15="-rand none -x2 --rand_type float -fil_layout=kcyx -in_layout=nchw -out_layout=nkhw -batchsize=64 -in_channels=32 -out_channels=32 -in_h=14 -in_w=14 -fil_h=1 -fil_w=1 --dilation_h=1 --dilation_w=1 --padding_h=1 --padding_w=1 --conv_stride_h=2 --conv_stride_w=2 --operation=conv2d_bwd_weight -t f16 -p=false"

#########################################
## conv2d_host_validation_f16_fwd.mlir ##
#########################################

## line 2 CHECK_KYXC_NHWC_NHWK1
## CPU validation failed
config4="-rand 1  -x2 --rand_type float -fil_layout=kyxc -in_layout=nhwc -out_layout=nhwk -p -t f16"

## line 4 CHECK_KYXC_NHWC_NHWK2
## CPU validation failed
config5="-rand 1  -x2 --rand_type float -fil_layout=kyxc -in_layout=nhwc -out_layout=nhwk -batchsize=64 -in_channels=4 -out_channels=64 -in_h=32 -in_w=32 -fil_h=3 -fil_w=3 --dilation_h=1 --dilation_w=1 --padding_h=0 --padding_w=0 --conv_stride_h=1 --conv_stride_w=1 -p=false -t f16"

## line 7 CHECK_KYXC_NHWC_NHWK3
config9="-rand 1  -x2 --rand_type float -fil_layout=kyxc -in_layout=nhwc -out_layout=nhwk -batchsize=64 -in_channels=4 -out_channels=64 -in_h=14 -in_w=14 -fil_h=3 -fil_w=3 --dilation_h=2 --dilation_w=2 --padding_h=0 --padding_w=0 --conv_stride_h=1 --conv_stride_w=1 -p=false -t f16"

## line 10 CHECK_KYXC_NHWC_NHWK4
config11="-rand 1  -x2 --rand_type float -fil_layout=kyxc -in_layout=nhwc -out_layout=nhwk -batchsize=64 -in_channels=4 -out_channels=64 -in_h=14 -in_w=14 -fil_h=3 -fil_w=3 --dilation_h=1 --dilation_w=1 --padding_h=0 --padding_w=0 --conv_stride_h=2 --conv_stride_w=2 -p=false -t f16"


## The following config failed in the nightly run 2022-07-12
## provided by Jungwood
config115="--operation conv2d -t f16 -p=false -fil_layout=gkyxc -in_layout=nhwgc -out_layout=nhwgk -batchsize=256 -groupsize=1 -in_channels=3 -out_channels=64 -in_h=230 -in_w=230 -fil_h=7 -fil_w=7 --dilation_h=1 --dilation_w=1 --padding_h=0 --padding_w=0 --conv_stride_h=2 --conv_stride_w=2  -rand 1 --rand_type float --x2"

## MLIR408
## The following config should fail on MI200 but passes
## provided by Krzysztof
config116="--operation conv2d -t f16 --fil_layout kcyx --in_layout nchw --out_layout nkhw --batchsize 128 --in_channels 8 --in_h 8 --in_w 8 --out_channels 128 --fil_w 4 --fil_h 4 --dilation_h 1 --dilation_w 1 --conv_stride_h 1 --conv_stride_w 1 --padding_h 0 --padding_w 0 -p=false -x2"


## conv2d_host_validation.mlir
## line 20 CHECK_RESNET101_NCHW_CONFIG2_WRW
## nightly-all 2022-07-14 Fixed e2e build
config117="--operation conv2d_bwd_weight -t f32 -p=false  -fil_layout=gkcyx -in_layout=ngchw -out_layout=ngkhw -batchsize=256 -groupsize=32 -in_channels=1024 -out_channels=1024 -in_h=7 -in_w=7 -fil_h=3 -fil_w=3 --dilation_h=1 --dilation_w=1 --padding_h=1 --padding_w=1 --conv_stride_h=1 --conv_stride_w=1 "


## Used for experimentation
config13="-rand 1 --rand_type float -fil_layout=kyxc -in_layout=nhwc -out_layout=nhwk -batchsize=64 -in_channels=4 -out_channels=64 -in_h=32 -in_w=32 -fil_h=3 -fil_w=3 --dilation_h=1 --dilation_w=1 --padding_h=0 --padding_w=0 --conv_stride_h=1 --conv_stride_w=1 -p=false -t bf16"

config16="-batchsize=256 -in_channels=256 -in_h=56 -in_w=56 -out_channels=512 -fil_h=1 -fil_w=1 --dilation_h=1 --dilation_w=1 --conv_stride_h=2 --conv_stride_w=2 --padding_h=0 --padding_w=0 --operation conv2d -fil_layout=gkcyx -in_layout=ngchw -out_layout=ngkhw -t i8 -x2"


# conv2d_regression_fwd/config_1_1.mlir
# failed with float random inputs
config28="-p --operation conv2d -fil_layout=kcyx -in_layout=nchw -out_layout=nkhw -t f32 -rand_type float  --arch gfx1030 -rand 1 -p_verify=off"

# conv2d_regression_bwd/config_17_7.mlir
config29="-groupsize=1 -batchsize=512 -in_channels=256 -out_channels=512 -in_h=7 -in_w=7 -fil_h=3 -fil_w=3 -dilation_h=1 -dilation_w=1 -conv_stride_h=1 -conv_stride_w=1 -padding_h_l=1 -padding_h_r=1 -padding_w_l=1 -padding_w_r=1 --operation conv2d_bwd_weight -fil_layout=kyxc -in_layout=nhwc -out_layout=nhwk -t f32 -rand_type float  --arch gfx90a -pv_with_gpu -rand 1"

# conv2d_regression_fwd/config_64_1.mlir
config30="-groupsize=1 -batchsize=256 -in_channels=128 -out_channels=128 -in_h=58 -in_w=58 -fil_h=3 -fil_w=3 -dilation_h=1 -dilation_w=1 -conv_stride_h=2 -conv_stride_w=2 -padding_h_l=0 -padding_h_r=0 -padding_w_l=0 -padding_w_r=0 --operation conv2d -fil_layout=kcyx -in_layout=nchw -out_layout=nkhw -t f32 -rand_type float  --arch gfx90a -pv -rand 1"

# bwd/config_1_5.mlir
config31="-groupsize=1 -batchsize=64 -in_channels=32 -out_channels=64 -in_h=32 -in_w=32 -fil_h=1 -fil_w=1 -dilation_h=1 -dilation_w=1 -conv_stride_h=1 -conv_stride_w=1 -padding_h_l=0 -padding_h_r=0 -padding_w_l=0 -padding_w_r=0 --operation conv2d_bwd_weight -fil_layout=kcyx -in_layout=nchw -out_layout=nkhw -t f32 -rand_type float  --arch gfx90a -rand 1 -RMS_threshold=0.00000003 -RMS_threshold=0.003"
