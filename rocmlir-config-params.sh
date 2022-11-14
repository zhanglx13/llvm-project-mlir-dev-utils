#! /bin/bash

declare -A configArr
declare -a orders
declare -A configVarToCL
declare -A configCLToVar
orders+=(operation)
orders+=(num_cu)
orders+=(filterLayout)
orders+=(inputLayout)
orders+=(outputLayout)
orders+=(groupSize)
orders+=(batchSize)
orders+=(inputChannel)
orders+=(outputChannel)
orders+=(inputHeight)
orders+=(inputWidth)
orders+=(filterHeight)
orders+=(filterWidth)
orders+=(dilationHeight)
orders+=(dilationWidth)
orders+=(strideHeight)
orders+=(strideWidth)
orders+=(paddingHeightLeft)
orders+=(paddingHeightRight)
orders+=(paddingWidthLeft)
orders+=(paddingWidthRight)
orders+=(tensorDataType)

## Command line options for each config parameter
configVarToCL[operation]=operation
configVarToCL[num_cu]=num_cu
configVarToCL[filterLayout]=fil_layout
configVarToCL[inputLayout]=in_layout
configVarToCL[outputLayout]=out_layout
configVarToCL[groupSize]=groupsize # can also use g
configVarToCL[batchSize]=batchsize
configVarToCL[inputChannel]=in_channels
configVarToCL[outputChannel]=out_channels
configVarToCL[inputHeight]=in_h
configVarToCL[inputWidth]=in_w
configVarToCL[filterHeight]=fil_h
configVarToCL[filterWidth]=fil_w
configVarToCL[dilationHeight]=dilation_h
configVarToCL[dilationWidth]=dilation_w
configVarToCL[strideHeight]=conv_stride_h
configVarToCL[strideWidth]=conv_stride_w
## padding_h
configVarToCL[paddingHeightLeft]=padding_h_l
configVarToCL[paddingHeightRight]=padding_h_r
## padding_w
configVarToCL[paddingWidthLeft]=padding_w_l
configVarToCL[paddingWidthRight]=padding_w_r
configVarToCL[tensorDataType]=t

configCLToVar[num_cu]=num_cu
configCLToVar[operation]=operation
configCLToVar[fil_layout]=filterLayout
configCLToVar[in_layout]=inputLayout
configCLToVar[out_layout]=outputLayout
configCLToVar[groupsize]=groupSize
configCLToVar[g]=groupSize
configCLToVar[batchsize]=batchSize
configCLToVar[in_channels]=inputChannel
configCLToVar[out_channels]=outputChannel
configCLToVar[in_h]=inputHeight
configCLToVar[in_w]=inputWidth
configCLToVar[fil_h]=filterHeight
configCLToVar[fil_w]=filterWidth
configCLToVar[dilation_h]=dilationHeight
configCLToVar[dilation_w]=dilationWidth
configCLToVar[conv_stride_h]=strideHeight
configCLToVar[conv_stride_w]=strideWidth
configCLToVar[padding_h_l]=paddingHeightLeft
configCLToVar[padding_h_r]=paddingHeightRight
configCLToVar[padding_w_l]=paddingWidthLeft
configCLToVar[padding_w_r]=paddingWidthRight
configCLToVar[t]=tensorDataType

##
## conv2d configs and their default values
##
refresh_config_with_cmd_defaults() {
    configArr[operation]=conv2d
    configArr[num_cu]=64
    configArr[filterLayout]=gkcyx
    configArr[inputLayout]=ngchw
    configArr[outputLayout]=ngkhw
    configArr[groupSize]=1
    configArr[batchSize]=-1
    configArr[inputChannel]=-1
    configArr[outputChannel]=-1
    configArr[inputHeight]=-1
    configArr[inputWidth]=-1
    configArr[filterHeight]=-1
    configArr[filterWidth]=-1
    configArr[dilationHeight]=1
    configArr[dilationWidth]=1
    configArr[strideHeight]=1
    configArr[strideWidth]=1
    configArr[paddingHeightLeft]=0
    configArr[paddingHeightRight]=0
    configArr[paddingWidthLeft]=0
    configArr[paddingWidthRight]=0
    configArr[tensorDataType]=f32
}

print_config() {
    ## $1: if populateDefaults
    ## $2: mode
    ##     0: single row without names
    ##     1: single row with names
    ##     2: multi rows
    if [[ $1 -eq 0 ]]; then
        for config in "${orders[@]}";
        do
            if [[ $2 -eq 0 ]]; then
                echo -n "${configArr[$config]} "
            elif [[ $2 -eq 1 ]]; then
                echo -n "-${configVarToCL[$config]}=${configArr[$config]} "
            else
                echo "$config (${configVarToCL[$config]}): ${configArr[$config]}"
            fi
        done
        if [[ $2 -lt 2 ]];then
            echo ""
        fi
    else
        ## If poulate defaults, then only print layouts
        echo -n "-operation=${configArr[operation]} "
        echo -n "-fil_layout=${configArr[filterLayout]} "
        echo -n "-in_layout=${configArr[inputLayout]} "
        echo -n "-out_layout=${configArr[outputLayout]} "
        echo -n "-t ${configArr[tensorDataType]} "
        echo "-p"
    fi
}
