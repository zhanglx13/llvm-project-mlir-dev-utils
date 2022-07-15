#! /bin/bash

##
## $1: input test file to split
## $2: dest dir to put the result unit tests
##

DEST_DIR=$2
INPUT_TEST=$1
INPUT_TEST_NAME=${INPUT_TEST%.mlir}
## Obtain the test name w/o path and extension
INPUT_TEST_NAME=${INPUT_TEST_NAME##*/}

count=0
while IFS= read -r line
do
    ## For each line of RUN
    if [[ $line == *"// RUN:"* ]]; then
        ## Extract the check_prefix
        check_prefix=$(echo `expr match "$line" '.*\(CHECK.*\)'`)
        ## Construct the unit test filename
        output_filename=${DEST_DIR}/${INPUT_TEST_NAME}_${check_prefix}.mlir
        echo "${output_filename}"
        ## Write the RUN and its corresponding CHECK into the output
        echo $line > ${output_filename}
        sed -n "/\/\/\ ${check_prefix}/p" ${INPUT_TEST} >> ${output_filename}
        ((count++))
    fi
done < ${INPUT_TEST}
echo "processed $count RUN"
