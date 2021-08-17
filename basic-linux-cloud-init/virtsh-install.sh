#!/bin/bash

# Cloud-linux images are available for each distro used in the script. Names are important.
# Uncomment curl line to download. Centos Stream is the only distro that does noat have a
# "latest" download option.

path=/var/lib/libvirt/images

# AlmaLinux8
file=almalinux8-base.qcow2
if test -f "$path/$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL -o $path/almalinux8-base.qcow2 https://repo.almalinux.org/almalinux/8/cloud/x86_64/images/AlmaLinux-8-GenericCloud-latest.x86_64.qcow2
fi

# CentosStream8
file=centos-stream8-base.qcow2
if test -f "$path/$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL -o $path/centos-stream8-base.qcow2 https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20210603.0.x86_64.qcow2
fi

# Debian11
file=debiantesting-base.qcow2
if test -f "$path/$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL -o $path/debiantesting-base.qcow2 https://cloud.debian.org/images/cloud/bullseye/daily/latest/debian-11-generic-amd64-daily.qcow2
fi

# Opensuse15.3
file=opensuse15.3-base.qcow2
if test -f "$path/$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL -o $path/opensuse15.3-base.qcow2 https://download.opensuse.org/repositories/Cloud:/Images:/Leap_15.3/images/openSUSE-Leap-15.3.x86_64-1.0.0-NoCloud-Build7.45.qcow2
fi


# Ubuntu20.04-LTS
file=ubuntu20.04-base.qcow2
if test -f "$path/$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL -o $path/ubuntu20.04-base.qcow2 https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
fi

# This creates a seeded iso from the cfg files that hold the cloud-init data.
# Script assumes all files reside in the $path working dir.
# One has a network config that is not necessary, but can do some nic configs.
#cloud-localds -v --network-config=network_config_static.cfg cloud-init.iso cloud_init.cfg
cloud-localds -v $path/cloud-init.iso $path/cloud_init.cfg

echo 'Hello, lets setup your VM. Enter exact info, no error checking.'

echo 'What OS for the VMs?'
select vmos in almalinux8 centos-stream8 debiantesting opensuse15.3 ubuntu20.04 quit; do

	case $vmos in
	    'quit')
		    echo 'Bye'
			break;;
	esac

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
		qemu-img create -b $path/$vmos-base.qcow2 -f qcow2 -F qcow2 $path/$name.qcow2 8G

		# Variables are set, install the VMs.
		virt-install --name $name \
			--virt-type kvm --memory $vmmem --vcpus $vmcpu \
			--boot hd,menu=on \
			--disk path=$path/cloud-init.iso,device=cdrom \
			--disk path=$path/$name.qcow2,device=disk \
			--graphics vnc \
			--os-type Linux --os-variant $vmos \
			--network network:default \
			--noautoconsole

	done

	echo You created $vmcount VMs of type $vmos, here are their names.
	echo -e ${array[*]}

	select oper in ip_output quit; do
    	echo Display IP (1) or quit(2).
		case $oper in
	    	ip_output)
		    	echo 'Disply ip of new VMs in array.'
		        	for i in $(seq 0 $((vmcount - 1))); do
                      getipdata=$(virsh domifaddr ${array[$i]} | grep ipv4)
                      printf "${array[$i]} leased $getipdata \n"
	        		done;;

	    	quit)
				echo 'Bye'
				break
		esac
	done
break
done
