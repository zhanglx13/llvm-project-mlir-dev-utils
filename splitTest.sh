#! /bin/bash

##
## $1: input test file to split
## $2: dest dir to put the result unit tests
## $3: datatype to extract
##     if not found, split the whole file

DEST_DIR=$2
INPUT_TEST=$1
INPUT_TEST_NAME=${INPUT_TEST%.mlir}
## Obtain the test name w/o path and extension
INPUT_TEST_NAME=${INPUT_TEST_NAME##*/}

count=0
searchStr="// RUN:"
outputTail=""
if [[ $# -eq 3 ]]; then
    ##
    ## Extract tests for data type specified by $3
    ##
    echo "input: ${INPUT_TEST_NAME}"
    echo "output dir: ${DEST_DIR}"
    echo "Look for data type $3"
    searchStr="-t $3"
    outputTail="_$3"
fi

while IFS= read -r line
do
    ## For each line of $searchStr but do not include lines with FIXME
    if [[ $line == *"$searchStr"* ]] && [[ $line != *"FIXME"* ]]; then
        ## Extract the check_prefix
        checkPrefix=$(echo `expr match "$line" '.*\(--check-prefix=.*\)'`)
        check_prefix=${checkPrefix#--check-prefix=}
        ## Construct the unit test filename
        output_filename=${DEST_DIR}/${INPUT_TEST_NAME}_${check_prefix}${outputTail}.mlir
        echo "${output_filename}"
        ## Write the RUN and its corresponding CHECK into the output
        echo $line > ${output_filename}
        sed -n "/\/\/\ ${check_prefix}/p" ${INPUT_TEST} >> ${output_filename}
        ((count++))
    fi
done < ${INPUT_TEST}
echo "processed $count lines"
