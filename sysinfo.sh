#! /bin/bash

UBUNTU_VERSION=$(lsb_release -a | sed -n '/Description/p' | awk '{print $3}')
LINUX_KERNEL=$(uname -r)
LINUX_KERNEL=${LINUX_KERNEL%%-generic}
ROCM_VERSION=$(dpkg -l | grep "rocm-dev " | awk '{print $3}')
CPU_NAME=$(cat /proc/cpuinfo | grep "model name" | head -n 1 | awk -F: '{print $2}')
NUM_PROCESSORS=$(cat /proc/cpuinfo | grep "siblings" | head -n 1 | awk -F: '{print $2}')
CPU_NAME=${CPU_NAME:1}
NUM_PROCESSORS=${NUM_PROCESSORS:1}
VBIOS=$(rocm-smi -v | grep "VBIOS version:"| head -n 1)
VBIOS=${VBIOS##*version: }
GPU_ARCH=$(rocm_agent_enumerator | tail -n 1)
NUM_GPUS=$(rocm_agent_enumerator | wc -l)
((NUM_GPUS--))
MB=$(sudo dmidecode -s baseboard-product-name)
BIOS_VENDOR=$(sudo dmidecode -s bios-vendor)
BIOS_VERSION=$(sudo dmidecode -s bios-version)
RELEASE_DATE=$(sudo dmidecode -s bios-release-date)


echo "CPU:            ${CPU_NAME}"
echo "processors:     ${NUM_PROCESSORS}"
echo "Ubuntu version: ${UBUNTU_VERSION}"
echo "Linux kernel:   ${LINUX_KERNEL}"
echo "ROCm version:   ${ROCM_VERSION}"
echo "GPU:            ${GPU_ARCH} x ${NUM_GPUS}"
echo "GPU vbios:      ${VBIOS}"
echo "Motherboard:    ${MB}"
echo "BIOS:           ${BIOS_VENDOR} ${BIOS_VERSION} (${RELEASE_DATE})"

extractLine() {
    ## $1: input
    ## $2: line number
    head -n $2 $1 | tail -1
}

## Obtain the number of HDs
hwinfo --disk > disk_info
NUM_HD=$(cat disk_info | grep "SysFS ID:" | wc -l)
for i in $(seq 1 ${NUM_HD})
do
    HD_SYSFS=$(cat disk_info | grep "SysFS ID:" | awk '{print $3}' | extractLine $i)
    HD_SYSFS=${HD_SYSFS##*/}
    HD_MODULE=$(cat disk_info | grep "Driver Modules:" | awk '{print $3}' | extractLine $i)
    HD_MODULE=${HD_MODULE#\"}
    HD_MODULE=${HD_MODULE%\"}
    HD_CONTROLLER=$(cat disk_info | grep "Attached to" | extractLine $i)
    HD_CONTROLLER=${HD_CONTROLLER##*\(}
    HD_CONTROLLER=${HD_CONTROLLER%%\ controller*}
    if [[ $i -eq 1 ]]; then
        echo "HD:             ${HD_SYSFS} (${HD_MODULE} ${HD_CONTROLLER})"
    else
        echo "                ${HD_SYSFS} (${HD_MODULE} ${HD_CONTROLLER})"
    fi
done

