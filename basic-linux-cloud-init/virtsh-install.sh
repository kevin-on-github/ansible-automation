#!/bin/bash


# Cloud-linux images are available for each distro used in the script. Names are important.

# AlmaLinux8 -
# curl -s https://repo.almalinux.org/almalinux/8/cloud/x86_64/images/AlmaLinux-8-GenericCloud-latest.x86_64.qcow2 \
#       -o almalinux8-base.qcow2
#
# CentOSStream8 - Verify the latest version as there is no 'latest/daily'
# curl - https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20210603.0.x86_64.qcow2 \
#       -o centos-stream8-base.qcow2
#
# Debian11 -
# curl -s https://cloud.debian.org/images/cloud/bullseye/daily/latest/debian-11-generic-amd64-daily.qcow2 \
#       -o debiantesting-base.qcow2
#

# This creates a seed img from the two cfg files that hold the cloud-init data.
# Script assumes all files reside in the current working dir.
cloud-localds -v --network-config=network_config_static.cfg test1-seed.img cloud_init.cfg

echo 'Hello, lets setup your VM. Enter exact info, no error checking.'

echo 'What OS (almalinux8, centos-stream8, debiantesting)?'
read vmos

echo 'How many vcpus (ex 1, 4)?'
read vmcpu

echo 'How much RAM (ex 1024, 2048, etc)?'
read vmmem

echo 'How many VMs do you want (ex 1, 6, etc)?'
read vmcount

for I in $( seq 1 $vmcount )
do

# Assign a random name to the VM.
    NAME=$vmos-cloud$I-$RANDOM


# Create a snapshot of the base image so each VM gets a clean start.
    qemu-img create -b $vmos-base.qcow2 -f qcow2 -F qcow2 $NAME.qcow2

# Variables are set, install the VMs.
    virt-install --name $NAME \
      --virt-type kvm --memory $vmmem --vcpus $vmcpu \
      --boot hd,menu=on \
      --disk path=test1-seed.img,device=cdrom \
      --disk path=$NAME.qcow2,device=disk \
      --graphics vnc \
      --os-type Linux --os-variant $vmos \
      --network network:default \
      --noautoconsole

done

# Specify a wait time for the VM to boot and grab an IP from dhcp. Their IP address wil display in terminal.
echo 'Do you want to wait for network info from dnsmasq (ex 0, 30, 90)? Enter# seconds.'
    read waittime
    sleep $waittime
     sudo virsh list --name | while read n ; do    [[ ! -z $n ]] && sudo virsh domifaddr $n; done