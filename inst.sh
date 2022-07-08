#! /bin/bash

cd ~/llvm-project-mlir/build/
cmake -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_FAT_LIBMLIRMIOPEN=1 ../
ninja libMLIRMIOpen
cmake --install . --component libMLIRMIOpen --prefix ~/dummy
