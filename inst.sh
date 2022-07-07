#! /bin/bash

cmake -G Ninja -DBUILD_FAT_LIBMLIRMIOPEN=1 ../
ninja libMLIRMIOpen
cmake --install . --component libMLIRMIOpen --prefix ~/dummy
