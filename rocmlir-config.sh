#! /bin/bash

source rocmlir-config-params.sh

CONFIG_DB=/home/zhanglx/config_db


## process the input mlir test file
##   1. Extract the config from RUN: rocmlir-gen
##   2. Extract values of each parameter and fill in the configArr
##   3. Insert the configArr into the config_db if not duplicate
process_input() {
    echo "process input file: ${INPUT_FILE}"
    cnt=0
    grep "RUN:" ${INPUT_FILE} > configs.txt
    while read -r line;
    do
        ((cnt++))
        ## extract config from each test
        line=${line%%|*}
        line=${line/\/\/\ RUN:\ rocmlir-gen/}
        line=${line/--arch\ \%arch}
        line=${line/\%pv}
        line=${line/\%random_data}
        line=${line/\%rocmlir_gen_flags}
        config=$(echo $line | xargs)
        #echo "Orig: $config"

        refresh_config_with_cmd_defaults
        update_config $config
    done < configs.txt
    echo "lines: $cnt"
}

## Use the given config ($1) to update the parameters in configArr
update_config() {
    ## $1: config input
    str=$config
    #str=" -padding_w=1"
    str=${str//--/-}
    #echo "new str: $str"
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
        #echo "str: $str"
        #echo "pair: $pair (${#pair})"
        ## -p
        if [[ "$pair" == "p" ]];then
            populateDefaults=1
            #echo "Populate defaults!!!"
        else
            ## key value pair
            key_value=($pair)
            key=${key_value[0]}
            value=${key_value[1]}
            #echo "key: ${key} value: ${value}"
            ## special case: -p=true or -p true
            if [[ "$key" == "p" ]]; then
                if [[ $valye == "true" ]];then
                    populateDefaults=1
                fi
            else
                ## Special case for layout: remove g
                if [[ "$key" == *"layout"* ]];then
                    value=${value/g/}
                    #echo "value: $value"
                fi
                ## special case for padding_
                if [[ "$key" == "padding_h" ]];then
                    configArr[paddingHeightLeft]=$value
                    configArr[paddingHeightRight]=$value
                elif [[ "$key" == "padding_w" ]];then
                    configArr[paddingWidthLeft]=$value
                    configArr[paddingWidthRight]=$value
                else
                    param=${configCLToVar[$key]}
                    #echo "param: $param"
                    configArr[$param]=$value
                fi
            fi
        fi
    done
    #echo -n "After: "
    #print_config $populateDefaults 1 | tee -a ${CONFIG_DB}
    #print_config $populateDefaults 1
    entry=$(print_config $populateDefaults 1)
    #echo "entry: $entry"
    match_and_insert "$entry"
}

## Match the given config entry in the config_db
## and insert the entry into the db if not exist
match_and_insert() {
    ## $1: config entry
    entry=$1
    shouldInsert=1
    entry=$(echo $entry | xargs)
    testN=1
    dbN=1
    while read -r line;
    do
        if [[ "$entry" == $"$line" ]]; then
            shouldInsert=0
            echo "match db $dbN"
            #echo "line: $line (${#line})"
            #echo "entr: $entry (${#entry})"
            break
        fi
        ((dbN++))
    done < ${CONFIG_DB}

    if [[ $shouldInsert -eq 1 ]];then
        echo "Insert new config into db: $entry"
        echo $entry >> ${CONFIG_DB}
    fi
}

check_config_str() {
    echo "Process input config string: ${CONFIG_STR}"
}


OPTIND=1

INPUT_FILE=""
CONFIG_STR=""
while getopts "f:c:" opt; do
    case "$opt" in
        f)
            INPUT_FILE=$OPTARG
            ;;
        c)
            CONFIG_STR=$OPTARG
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


if [[ ${INPUT_FILE} == "" ]] && [[ ${CONFIG_STR} == "" ]];then
    echo "Must provide either input file (-f) or config string (-c)"
    exit 0
fi

## Process input file mode
if [[ ${INPUT_FILE} != "" ]];then
    process_input
fi

## Check config string mode
if [[ ${CONFIG_STR} != "" ]];then
    check_config_str
fi




#refresh_config_with_cmd_defaults
#print_config 0
#print_config 1
