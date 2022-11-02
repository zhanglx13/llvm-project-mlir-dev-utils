#!/bin/bash

while true
do
    EDGE_TEMP=$(rocm-smi -t | grep edge | awk '{print $7}')
    echo "${EDGE_TEMP}" | ts '[%H:%M:%S]'
    sleep .5
done
