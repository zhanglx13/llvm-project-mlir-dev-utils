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

# setup orgfiles
git clone https://$1@github.com/zhanglx13/orgfiles.git

git clone https://github.com/llvm/llvm-project.git

# Download MIOpen
# git clone https://$1@github.com/ROCmSoftwarePlatform/MIOpen.git

# Download triton
git clone https://$1@github.com/triton-lang/triton.git OAI-triton
git clone https://$1@github.com/ROCm/triton.git AMD-triton


git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global user.name "Lixun Zhang"
git config --global user.email "lixun.zhang@amd.com"
