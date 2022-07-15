#! /bin/bash

##
## $1: validator: cpu or gpu
## $2: result filename
##

result_filename=$2
for config in 1 2 3 4
do
    echo "Running config $config ..." | tee -a ${result_filename}
    for thr in 0.25 0.2 0.15 0.1 0.05 0.01 0.001
    do
        for i in  $(seq 0 1 9)
        do
            result=$(./run.sh -gdre $thr -v $1 -n $config | tail -1)
            echo "  $i ==> $result" | tee -a ${result_filename}
        done
    done
done
