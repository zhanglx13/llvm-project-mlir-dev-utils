#! /bin/bash

## $1: filename
remove_lit_check()
{
    sed -i '/Unranked Memref base@ = 0x.* rank = 1 offset = 0 sizes = \[1\] strides = \[1\] data =/d' $1
    sed -i 's/\[1\]/\[1 1 1\]/g' $1
}

## $1: folder name
for entry in $1/*
do
    if [[ -d "$entry" ]]; then
        echo "Found folder $entry"
    else
        echo "file: $entry"
        remove_lit_check $entry
    fi
done
