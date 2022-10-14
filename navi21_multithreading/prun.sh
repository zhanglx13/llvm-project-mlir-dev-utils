#! /bin/bash

## $1: number of workers
## $2: number of instances

echo "Running $1 workers for $2 instances"

parallel -j$1 bash run_config.sh ::: $(seq 1 $2)
