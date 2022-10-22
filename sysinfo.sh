#! /bin/bash

UBUNTU_VERSION=$(lsb_release -a | sed -n '/Description/p' | awk '{print $3}')
LINUX_KERNEL=$(uname -r)
LINUX_KERNEL=${LINUX_KERNEL%%-generic}
ROCM_VERSION=$(ls -al /opt | sed -n '/rocm-/p' | tail -n 1 | awk '{print $(NF)}')
ROCM_VERSION=${ROCM_VERSION##rocm-}
CPU_NAME=$(cat /proc/cpuinfo | grep "model name" | head -n 1 | awk -F: '{print $2}')
NUM_PROCESSORS=$(cat /proc/cpuinfo | grep "siblings" | head -n 1 | awk -F: '{print $2}')
CPU_NAME=${CPU_NAME:1}
NUM_PROCESSORS=${NUM_PROCESSORS:1}
VBIOS=$(rocm-smi -v | grep "VBIOS version:"| head -n 1)
VBIOS=${VBIOS##*version: }
NUM_GPUS=$(rocm_agent_enumerator | wc -l)
#NUM_GPUS=$NUM_GPUS-1
((NUM_GPUS--))
MB=$(sudo dmidecode -s baseboard-product-name)

echo "CPU:            ${CPU_NAME}"
echo "processors:     ${NUM_PROCESSORS}"
echo "Ubuntu version: ${UBUNTU_VERSION}"
echo "Linux kernel:   ${LINUX_KERNEL}"
echo "ROCm version:   ${ROCM_VERSION}"
echo "Number of GPUs: ${NUM_GPUS}"
echo "GPU vbios:      ${VBIOS}"
echo "Motherboard:    ${MB}"
