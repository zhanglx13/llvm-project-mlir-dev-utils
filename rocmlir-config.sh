#! /bin/bash


declare -A configArr
declare -a orders
declare -A configCLArr
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
configArr[operation]=operation
configArr[num_cu]=num_cu
configArr[filterLayout]=fil_layout
configArr[inputLayout]=in_layout
configArr[outputLayout]=out_layout
configArr[groupSize]=groupsize # can also use g
configArr[batchSize]=batchsize
configArr[inputChannel]=in_channels
configArr[outputChannel]=out_channels
configArr[inputHeight]=in_h
configArr[inputWidth]=in_w
configArr[filterHeight]=fil_h
configArr[filterWidth]=fil_w
configArr[dilationHeight]=1
configArr[dilationWidth]=1
configArr[strideHeight]=1
configArr[strideWidth]=1
configArr[paddingHeightLeft]=0
configArr[paddingHeightRight]=0
configArr[paddingWidthLeft]=0
configArr[paddingWidthRight]=0
configArr[tensorDataType]=f32
##
## conv2d configs and their default values
##
refresh_config_with_defaults_cmd() {
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
    ## $1: mode
    ##     0: single row
    ##     1: multi rows
    for config in "${orders[@]}";
    do
        if [[ $1 -eq 0 ]]; then
            echo -n "${configArr[$config]} "
        else
            echo "$config: ${configArr[$config]}"
        fi
    done
    if [[ $1 -eq 0 ]];then
        echo ""
    fi
}
## operation conv2d
## num_cu 64
## filterLayout gkcyx
## inputLayout ngchw
## outputLayout ngkhw
## groupSize 1
## batchSize -1
## inputChannel -1
## outputChannel -1
## inputHeight -1
## inputWidth -1
## filterHeight -1
## filterWidth -1
## dilationHeight 1
## dilationWidth 1
## strideHeight 1
## strideWidth 1
## paddingHeightLeft 0
## paddingHeightRight 0
## paddingWidthLeft 0
## paddingWidthRight 0
## tensorDataType f32


refresh_config_with_defaults_cmd
print_config 0
print_config 1
