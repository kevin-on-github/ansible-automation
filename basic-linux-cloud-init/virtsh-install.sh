#!/bin/bash

# Cloud-linux images are available for each distro used in the script. Names are important.
# Uncomment curl line to download. Centos Stream is the only distro that does noat have a
# "latest" download option.

path=/var/lib/libvirt/images/

# AlmaLinux8
file=almalinux8-base.qcow2
if test -f "$path$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL https://repo.almalinux.org/almalinux/8/cloud/x86_64/images/AlmaLinux-8-GenericCloud-latest.x86_64.qcow2 -o $path'almalinux8-base.qcow2'
fi

# AlmaLinux9
file=almalinux9-base.qcow2
if test -f "$path$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2 -o $path'almalinux9-base.qcow2'
fi

# CentosStream8
file=centos-stream8-base.qcow2
if test -f "$path$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20220125.1.x86_64.qcow2 -o $path'centos-stream8-base.qcow2'
fi

# CentosStream9
file=centos-stream9-base.qcow2
if test -f "$path$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-20220627.1.x86_64.qcow2 -o $path'centos-stream9-base.qcow2'
fi


# Debian11
file=debian11-base.qcow2
if test -f "$path$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL https://cloud.debian.org/images/cloud/bullseye/daily/latest/debian-11-generic-amd64-daily.qcow2 -o $path'debian11-base.qcow2'
fi

# Opensuse15.4
file=opensuse15.3-base.qcow2
if test -f "$path$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL https://download.opensuse.org/distribution/openSUSE-stable/appliances/openSUSE-Leap-15.4-JeOS.x86_64-15.4-OpenStack-Cloud-Current.qcow2 -o $path'opensuse15.3-base.qcow2'
fi


# Ubuntu20.04-LTS
file=ubuntu20.04-base.qcow2
if test -f "$path$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img -o $path'ubuntu20.04-base.qcow2'
fi

# This creates a seeded iso from the cfg files that hold the cloud-init data.
# Script assumes all files reside in the current working dir.
# One has a network config that is not necessary, but can do some nic configs.
#cloud-localds -v --network-config=network_config_static.cfg cloud-init.iso cloud_init.cfg
#cloud-localds -v cloud-init.iso cloud_init.cfg


# This appears to be the new hottness for seed creation
# Lets give this a shot.

genisoimage -output seed.iso -volid cidata -joliet -rock user-data meta-data

echo 'Hello, lets setup your VM. Enter exact info, no error checking.'

echo 'What OS (almalinux8-9, centos-stream8-9, debian11, opensuse15.4, ubuntu20.04)?'
select vmos in almalinux8 almalinux9 centos-stream8 centos-stream9 debian11 opensuse15.3 ubuntu20.04; do
	echo $vmos selected.

	echo 'How many vcpus (ex 1, 4)?'
	read vmcpu

	echo 'How much RAM (ex 1024, 2048, etc)?'
	read vmmem

	echo 'How many VMs do you want (ex 1, 6, etc)?'
	read vmcount

	for i in $(seq 1 $vmcount); do

		# Assign a random name to the VM.
		name=$vmos-cloud$i-$RANDOM
		array+=($name)

		# Create a snapshot of the base image so each VM gets a clean start.
		qemu-img create -b $vmos-base.qcow2 -f qcow2 -F qcow2 $name.qcow2 32G

		# Variables are set, install the VMs.
		virt-install --name $name \
			--virt-type kvm --memory $vmmem --vcpus $vmcpu \
			--boot hd,menu=on \
			--import \
			--cdrom seed.iso \
			--disk path=$name.qcow2,device=disk \
			--graphics vnc \
			--os-variant linux2020 \
			--network network:default \
			--noautoconsole

	done

	echo You created $vmcount VMs of type $vmos, here are their names.
	echo -e ${array[*]}

	# Specify a wait time for the VM to boot and grab an IP from dhcp. Their IP address wil display in terminal.

	while true; do
		for i in $(seq 0 $((vmcount - 1))); do
			getipdata=$(virsh domifaddr ${array[$i]} | grep ipv4)
			printf "${array[$i]} leased $getipdata \n"
		done
		sleep 5

	done
	break
done
