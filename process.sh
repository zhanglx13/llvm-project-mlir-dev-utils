#! /bin/bash

for entry in miopen-gen_configs/*
do
    ## remove the first 7 lines gfx908
    # sed -i -e '1,7d' $entry
    #echo "$(wc -l $entry)"
    ## extract the line starting "miopen-gen command:"
    #sed -n -i '/miopen-gen command:/p' $entry
    ## remove the "miopen-gen command: ./bin/miopen-gen -ph " at the beginning
    #sed -i 's!miopen-gen command:  ./bin/miopen-gen -ph !!' $entry
done
