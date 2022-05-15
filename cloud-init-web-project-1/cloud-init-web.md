# Cloud-linux
- Various images are available for each distro used in the [virt-install.sh](https://raw.githubusercontent.com/kevin-on-github/ansible-automation/main/basic-linux-cloud-init/virtsh-install.sh) script. Comment out the curl lines to skip downloading the images.

```
path=/var/lib/libvirt/images/

# AlmaLinux8
file=almalinux8-base.qcow2
if test -f "$path$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL https://repo.almalinux.org/almalinux/8/cloud/x86_64/images/AlmaLinux-8-GenericCloud-latest.x86_64.qcow2 -o $path'almalinux8-base.qcow2'
fi

# CentosStream8
file=centos-stream8-base.qcow2
if test -f "$path$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20220125.1.x86_64.qcow2 -o $path'centos-stream8-base.qcow2'
fi

# Debian11
file=debian11-base.qcow2
if test -f "$path$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL https://cloud.debian.org/images/cloud/bullseye/daily/latest/debian-11-generic-amd64-daily.qcow2 -o $path'debian11-base.qcow2'
fi

# Opensuse15.3
file=opensuse15.3-base.qcow2
if test -f "$path$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL https://download.opensuse.org/repositories/Cloud:/Images:/Leap_15.3/images/openSUSE-Leap-15.3.x86_64-1.0.1-NoCloud-Build2.146.qcow2 -o $path'opensuse15.3-base.qcow2'
fi


# Ubuntu20.04-LTS
file=ubuntu20.04-base.qcow2
if test -f "$path$file"; then
    echo "$file exists."
else 
    echo "$file does not exist. Downloading..."
    curl -SL https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img -o $path'ubuntu20.04-base.qcow2'
fi
```

### This creates a seed img from the [user-data](https://raw.githubusercontent.com/kevin-on-github/ansible-automation/main/basic-linux-cloud-init/user-data) and [meta-data] (https://raw.githubusercontent.com/kevin-on-github/ansible-automation/main/basic-linux-cloud-init/meta-data) files.

```
genisoimage -output seed.iso -volid cidata -joliet -rock user-data meta-data

# content of user-data and meta-data files. Make sure to edit the file for your specific deployment needs.

#cloud-config
#user-data
hostname: linux-cloud
fqdn: linux-cloud.localdomain
manage_etc_hosts: true
users:
  - name: <your username>
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    home: /home/<your username>
    shell: /bin/bash
    lock_passwd: false
    ssh-authorized-keys:
      - <your public ssh key>
# only cert auth via ssh (console access can still login)
ssh_pwauth: false
disable_root: false
chpasswd:
  list: |
     <yourusername>:<your password>
  expire: False

package_update: true
packages:
  - qemu-guest-agent
  - nano
  - (insert all the package names here)
# written to /var/log/cloud-init-output.log
final_message: "The system is finally up, after $UPTIME seconds"


#meta-data
instance-id: iid-local01\nlocal-hostname: cloudimg

```

### With files in the right location, this user input will build the VMs.
```
echo 'Hello, lets setup your VM. Enter exact info, no error checking.'

echo 'What OS (almalinux8, centos-stream8, debian11)?'
select vmos in almalinux8 centos-stream8 debian11 opensuse15.3 ubuntu20.04; do
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
		qemu-img create -b $vmos-base.qcow2 -f qcow2 -F qcow2 $name.qcow2 12G

		# Variables are set, install the VMs.
		virt-install --name $name \
			--virt-type kvm --memory $vmmem --vcpus $vmcpu \
			--boot hd,menu=on \
			--import \
			--cdrom seed.iso \
			--disk path=$name.qcow2,device=disk \
			--graphics vnc \
			--os-variant $vmos \
			--network network:default \
			--noautoconsole

	done

	echo You created $vmcount VMs of type $vmos, here are their names.
	echo -e ${array[*]}
```

### I put this in to just poll virtsh and print the ip addresses assigned to the VMs. 
```
	# Ctrl+C to quit. The IP addresses will display in terminal.

	while true; do
		for i in $(seq 0 $((vmcount - 1))); do
			getipdata=$(virsh domifaddr ${array[$i]} | grep ipv4)
			printf "${array[$i]} leased $getipdata \n"
		done
		sleep 5

	done
	break
done
```

# Script done. Enjoy your VMs.