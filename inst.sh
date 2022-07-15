#! /bin/bash

##
## Switch between test_debug and test_orig
## $1: debug or orig
##     Only use test_debug if $1 is explicitly set to debug
##     All other cases will use the orig test

cd ~/llvm-project-mlir/mlir
if [[ $1 == "debug" ]];then
    echo "switch to test_debug"
    rm -r test
    cp -r test_debug test
else
    echo "switch to test_orig"
    rm -r test
    cp -r test_orig test
fi
