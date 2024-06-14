FROM rocm/pytorch:latest-release

ARG UID=
ARG GID=

## Upgrade pip to the latest version
RUN pip install --upgrade pip
## Upgrade pytorch to the latest
RUN pip uninstall -y torch torchvision torchaudio
RUN pip3 install --pre torch  --index-url https://download.pytorch.org/whl/nightly/rocm6.1
## Remove the pre-installed triton
RUN pip uninstall -y triton
RUN rm -rf /opt/conda/envs/py_3.9/lib/python3.9/site-packages/triton
## Install amd_smi (should not be necessary later)
#RUN pip install /opt/rocm/share/amd_smi


ENV TZ=America/Chicago
RUN apt-get update
# Install compiler; change default to clang

# Here is all personal preference, with a few notes on software you may find useful
RUN apt-add-repository ppa:kelleyk/emacs && apt-get update
RUN apt-get install -y vim less  mlocate \
    silversearcher-ag keychain htop rcm
#RUN apt-get install emacs
#RUN ln -sv /usr/bin/clangd-12 /usr/bin/clangd


# Adjust this to match the UID/GID and name on dev machine
# --shell here is optional and my preference
# IMPORTANT: CHANGE THE LINES BELOW IF BOROWING THIS
# Both the IDs and the username need to be changed to yours
RUN addgroup --gid {GID} zhanglx
RUN useradd -d /home/zhanglx -g zhanglx --no-create-home -u {UID} --shell /bin/bash zhanglx
#RUN chown root:root /etc/gshadow
RUN usermod -aG sudo zhanglx
RUN usermod -aG video zhanglx
RUN usermod -aG render zhanglx
# The /var is only needed on lockhart
RUN mkdir /home/zhanglx
RUN mkdir /home/zhanglx/exa
RUN mkdir /home/zhanglx/exa/bin
COPY ./.bashrc /home/zhanglx/
COPY ./exa /home/zhanglx/exa/bin/
RUN chown -R zhanglx:zhanglx /home/zhanglx 

# Make sudo work without a password
RUN sed -i~ -e 's/%sudo\tALL=(ALL:ALL) ALL/%sudo\tALL=(ALL:ALL) NOPASSWD:ALL/g' /etc/sudoers
#RUN visudo -c

# CHANGE THIS
USER zhanglx
WORKDIR /home/zhanglx
ENV HOME=/home/zhanglx

# git alias
RUN git config --global alias.co checkout
RUN git config --global alias.br branch
RUN git config --global alias.ci commit
RUN git config --global alias.st status
RUN git config --global user.name "Lixun Zhang"
RUN git config --global user.email "lixun.zhang@amd.com"


#ENV ROCR_VISIBLE_DEVICES=3
# Keep container alive
# CMD tmux new-session -d && tail -f /dev/null
CMD /bin/bash
