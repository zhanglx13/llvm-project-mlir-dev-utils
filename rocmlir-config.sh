#! /bin/bash

declare -A configArr
declare -a orders
declare -A configVarToCL
declare -A configCLToVar
## Define conv parameters in order
orders+=(operation)
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
## Convert variable to command line option
configVarToCL[operation]=operation
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

## Convert command line option to variable
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

#ROCMLIR_DIR=$(git rev-parse --show-toplevel || echo "${HOME}/rocMLIR/")
ROCMLIR_DIR=${HOME}/rocMLIR/
E2E_CONV_DB_DIR=${ROCMLIR_DIR}/mlir/test/e2e
declare -a convDB
convDB+=(MixedConvLayouts)
convDB+=(PaddedGemmConfig)
convDB+=(Resnet50Config)
convDB+=(Resnext101Config)
convDB+=(conv2d_regression_fwd)
convDB+=(conv2d_regression_bwd)
convDB+=(conv2d_wrw_perf_config)

populateDefaults=0

print_usage() {
    echo "Usage: ./rocmlir-config.sh -m buildDB"
    echo "-m buildDB: build up config database according to the input file"
    echo "   -f <inputfile>: can be *.mlir test file or *.toml configuration file"
    echo "   -d <database>:  empty file or contains lines of entries, whose format is controlled by"
    echo "        -o <0|1|2>: 0: single row without names"
    echo "                    1: single row with names (default)"
    echo "                    2: multi row with names"
    echo "        -y: drop -t (datatype)"
    echo "        -p: drop -operation"
    echo "        -l: drop layouts"
    echo "        -s: search mode, i.e. do not insert config into the database"
    echo "-m checkConfig -c \"<config string>\": search the given config in the conv database:"
    print_convDB
}

print_convDB() {
    for db in ${convDB[@]};
    do
        echo -n "    $db "
        if [ -f ${E2E_CONV_DB_DIR}/$db.toml ];then
            printf "\xE2\x9C\x94\n"
        else
            printf "\xE2\x9D\x8C\n"
        fi
    done
}

##
## conv2d configs and their default values
##
refresh_config_with_cmd_defaults() {
    configArr[operation]=conv2d
    configArr[num_cu]=64
    configArr[filterLayout]=kcyx
    configArr[inputLayout]=nchw
    configArr[outputLayout]=nkhw
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
    ## $2: format
    ##     0: single row without names
    ##     1: single row with names
    ##     2: multi rows
    ## $3: drop -t
    ## $4: drop operation
    ## $5: drop layouts
    pDefaults=$1
    format=$2
    mode=$3
    dropType=$3
    dropDir=$4
    dropLayouts=$5
    if [[ $pDefaults -eq 0 ]]; then
        for config in "${orders[@]}";
        do
            if [[ $dropType -eq 1 ]] && [[ "$config" == "tensorDataType" ]];then
                continue
            fi
            if [[ $dropDir -eq 1 ]] && [[ "$config" == "operation" ]];then
                continue
            fi
            if [[ $dropLayouts -eq 1 ]] && [[ "$config" == *"Layout"* ]];then
                continue
            fi

            if [[ $format -eq 0 ]]; then
                echo -n "${configArr[$config]} "
            elif [[ $format -eq 1 ]]; then
                echo -n "-${configVarToCL[$config]}=${configArr[$config]} "
            else
                echo "$config (${configVarToCL[$config]}): ${configArr[$config]}"
            fi
        done
        if [[ $format -lt 2 ]];then
            echo ""
        fi
    else
        print_config_with_defaults $dropType $dropDir $dropLayouts
    fi
}

print_config_with_defaults() {
    ## $1: dropType?
    ## $2: dropDir?
    ## $3: dropLayouts?
    dropType=$1
    dropDir=$2
    dropLayouts=$3

    if [[ $dropDir -eq 0 ]];then
        echo -n "-operation=${configArr[operation]} "
    fi
    if [[ $dropLayouts -eq 0 ]];then
        echo -n "-fil_layout=${configArr[filterLayout]} "
        echo -n "-in_layout=${configArr[inputLayout]} "
        echo -n "-out_layout=${configArr[outputLayout]} "
    fi
    if [[ $dropType -eq 0 ]];then
        echo -n "-t ${configArr[tensorDataType]} "
    fi
    echo "-p"
}


## process the input mlir test file or toml configuration file
##   1. Extract the config from RUN: rocmlir-gen or config =
##   2. Extract values of each parameter and fill in configArr
##   3. Insert the configArr into the config_db if not duplicate
process_input() {
    if [[ "${INPUT_FILE}" == "" ]] || [[ "${CONFIG_DB}" == "" ]];then
        echo "Need input file (-f <input filename>) and db (-d <db filename>)"
        exit 0
    fi
        if [[ $verbose -eq 1 ]];then
        echo "processing input file: ${INPUT_FILE}"
    fi
    ## Check input file format
    input_format=""
    if [[ ${INPUT_FILE} == *".mlir"* ]];then
        input_format="mlir"
        grep "rocmlir-gen" ${INPUT_FILE} > configs.txt
    elif [[ ${INPUT_FILE} == *".toml"* ]];then
        input_format="toml"
        grep "config =" ${INPUT_FILE} > configs.txt
    else
        echo "Unkonw format of input file: ${INPUT_FILE} (must be .mlir or .toml)"
        exit 0
    fi

    cnt=0
    while read -r line;
    do
        ((cnt++))
        if [[ $verbose -eq 1 ]];then
            echo "#### test $cnt in ${INPUT_FILE}"
        fi
        entry=$(format_config "$line")
        match_and_insert "$entry" $INSERT
    done < configs.txt
    if [[ $verbose -eq 1 ]];then
        echo "processed $cnt tests in ${INPUT_FILE}"
    fi
}

## Remove unuseful information from the given line or string
preprocess_config() {
    ## $1: line or string that contains a config
    line=$1
    ## Only extract contents after rocmlir-gen
    line=${line%%|*}
    line=${line/\/\/\ RUN:\ rocmlir-gen/}
    #line=${line/--arch\ \%arch}
    ## remove lit defined variables
    line=${line/\%pv}
    line=${line/\%random_data}
    line=${line/\%rocmlir_gen_flags}
    ## remove spaces
    config=$(echo $line | xargs)
    echo "$config"
}

## Format the given config
format_config() {
    ## $1: target config
    ## return: formatted entry
    config=$(preprocess_config "$1")
    refresh_config_with_cmd_defaults
    update_config "$config"
    ## pretty print the config
    entry=$(print_config $populateDefaults $FORMAT ${DROP_DT} ${DROP_DIR} ${DROP_LAYOUTS})
    echo $entry | xargs
}

## Use the given config ($1) to update the parameters in configArr
## and set populateDefaults if -p or -p=true is in the config
update_config() {
    ## $1: config input
    str=$1
    ## replace -- with - for easy processing
    str=${str//--/-}
    populateDefaults=0
    while [[ "$str" == *"-"* ]];
    do
        ## Keep processing if there is an option in str
        ## extract the last key-value pair from str
        pair=$(echo `expr "$str" : '.*\(-.*\)'`)
        ## replace = with space and remove - for easy processing
        pair=${pair//=/ }
        pair=${pair//-/}
        ## Remove the last key-value pair from str
        str=${str%-*}
        ## special case for -p
        if [[ "$pair" == "p" ]];then
            populateDefaults=1
        else
            ## key value pair
            key_value=($pair)
            key=${key_value[0]}
            value=${key_value[1]}
            ## special case: -p=true or -p true
            if [[ "$key" == "p" ]]; then
                if [[ $valye == "true" ]];then
                    populateDefaults=1
                fi
            else
                ## Special case for layout: remove g
                if [[ "$key" == *"layout"* ]];then
                    value=${value/g/}
                fi
                ## special case for padding_
                if [[ "$key" == "padding_h" ]];then
                    configArr[paddingHeightLeft]=$value
                    configArr[paddingHeightRight]=$value
                elif [[ "$key" == "padding_w" ]];then
                    configArr[paddingWidthLeft]=$value
                    configArr[paddingWidthRight]=$value
                else
                    if [[ ${configCLToVar[$key]} ]];then
                        ## ignore cmd options not defined
                        ## E.g. -rand_type and -arch %arch/gfx1030
                        param=${configCLToVar[$key]}
                        configArr[$param]=$value
                    fi
                fi
            fi
        fi
    done
}

## Match the given config entry in the config_db
## and insert the entry into the db if not exist
match_and_insert() {
    ## $1: config entry
    ## $2: mode
    ##     1: match only, do not insert the entry
    ##     2: insert the entry if not match
    entry=$1
    shouldInsert=1
    entry=$(echo $entry | xargs)
    dbN=1
    if [ -f ${CONFIG_DB} ];then
        while read -r line;
        do
            if [[ "$entry" == $"$line" ]]; then
                shouldInsert=0
                if [[ $verbose -eq 1 ]];then
                    echo "  Match config $dbN in ${CONFIG_DB}"
                fi
                break
            fi
            ((dbN++))
        done < ${CONFIG_DB}
    fi

    if [[ $shouldInsert -eq 1 ]] && [[ $2 -eq 2 ]];then
        if [[ $verbose -eq 1 ]];then
            echo "    Insert new config into ${CONFIG_DB}"
        fi
        echo $entry >> ${CONFIG_DB}
    elif [[ $shouldInsert -eq 1 ]] && [[ $verbose -eq 1 ]];then
        echo "    Not found in ${CONFIG_DB}"
    fi
}



gen_toml_body(){
    if [[ "${CONFIG_DB}" == "" ]] || [[ "${TOML_FILE}" == "" ]];then
        echo "Need db (-d <db filenme>) and toml file (-t <toml filename>)"
        exit 0
    fi
    while read -r line;
    do
        echo "[[suite.test]]" >> ${TOML_FILE}
        echo "config = \"$line\"" >> ${TOML_FILE}
        echo "" >> ${TOML_FILE}
    done < ${CONFIG_DB}
}

check_config_str() {
    if [[ "${CONFIG_STR}" == "" ]];then
        echo "Need config string (-c <config>)"
        exit 0
    fi
    #echo "Process input config string: ${CONFIG_STR}"
    DROP_DT=1
    DROP_DIR=1
    DROP_LAYOUTS=1
    entry=$(format_config "${CONFIG_STR}")
    echo "entry: $entry"
    foundOne=0
    for db in ${convDB[@]};
    do
        #echo "Checking ${E2E_CONV_DB_DIR}/$db.toml"
        ## for each toml file t.toml
        ## 1. construct a database t.db
        ## 2. search entry in t.db
        ## 3. remove t.db
        ./rocmlir-config.sh -m buildDB -f ${E2E_CONV_DB_DIR}/$db.toml -d $db.db -ypl
        dbN=1
        while read -r line;
        do
            if [[ "$entry" == "$line" ]];then
                echo "!! Match config $dbN in $db.toml !!"
                foundOne=1
            fi
            ((dbN++))
        done < $db.db
        rm $db.db
    done
    ## Not found in any database
    if [[ $foundOne -eq 0 ]];then
        echo "!! Not found in any database !!"
    fi
}


OPTIND=1

INPUT_FILE=""  # -f
CONFIG_STR=""  # -c
CONFIG_DB=""   # -d
TOML_FILE=""   # -t
MODE=""        # -m
FORMAT=1       # -o
DROP_DT=0      # -y
DROP_DIR=0     # -p
DROP_LAYOUTS=0 # -l
INSERT=2       # -s
verbose=0      # -v
while getopts "hf:c:m:d:t:o:yplsv" opt; do
    case "$opt" in
        h)
            print_usage
            exit 0
            ;;
        f)
            INPUT_FILE=$OPTARG
            ;;
        c)
            CONFIG_STR=$OPTARG
            ;;
        m)
            MODE=$OPTARG
            ;;
        d)
            CONFIG_DB=$OPTARG
            ;;
        t)
            TOML_FILE=$OPTARG
            ;;
        o)
            FORMAT=$OPTARG
            ;;
        y)
            DROP_DT=1
            ;;
        p)
            DROP_DIR=1
            ;;
        l)
            DROP_LAYOUTS=1
            ;;
        s)
            INSERT=1
            ;;
        v)
            verbose=1
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

if [[ "$MODE" == "" ]];then
    echo "Must specify mode (-m checkConfig|buildDB|genToml)"
    exit 0
fi

if [[ "$MODE" == "checkConfig" ]];then
    check_config_str
elif [[ "$MODE" == "buildDB" ]];then
    process_input
elif [[ "$MODE" == "genToml" ]];then
    gen_toml_body
else
    echo "Unknow mode: $MODE"
    echo "Must be one of checkConfig|buildDB|genToml"
    exit 0
fi

## ./rocmlir-config.sh -m genToml -d /home/zhanglx/conv2d_host_validation_f32_fwd_db -t /home/zhanglx/rocMLIR/mlir/test/e2e/conv2d_host_validation_f32_fwd.toml
