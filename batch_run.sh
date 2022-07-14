#! /bin/bash

for config in "1"
do
    echo "Running config $config ..."
    for thr in "0.2 0.15 0.1 0.05 0.01"
    do
        for i in  $(seq 0 1 9)
        do
            result=$(./run.sh -gdrve $thr -n $config | tail -1)
            echo "  $i ==> $result"
        done
    done
done
