#! /bin/bash

##
## $1: username:token 
##

if [[ $# -lt 1 ]]; then
    echo "Need to provide credentials to download github repos"
    echo "./container_bringup.sh username:token"
    exit
fi



# setup emacs
git clone https://$1@github.com/zhanglx13/emacs_settings.git
mv emacs_settings ~/.emacs.d

# setup myscrips
git clone https://$1@github.com/zhanglx13/llvm-project-mlir-dev-utils.git
mv llvm-project-mlir-dev-utils myscripts

# setup orgfiles
git clone https://$1@github.com/zhanglx13/orgfiles.git

# Download rocMLIR
git clone https://$1@github.com/ROCm/rocMLIR.git

# Download MIOpen
# git clone https://$1@github.com/ROCmSoftwarePlatform/MIOpen.git

# Download triton
git clone https://$1@github.com/zhanglx13/triton.git AMD-triton
git clone https://$1@github.com/triton-lang/triton.git OAI-triton

# Download msft
git clone https://$1@github.com/ROCmSoftwarePlatform/msft_amd_ai_operators.git
