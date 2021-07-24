## Deploy a group of similar linux machines via cloud-init and base image.
 - There are some requirements here. Conform to the naming convention used within the virtsh-install.sh script.
 - Script uses virt-install within a KVM/libvirtd virtualization system.
 - All files will function within the working directory, for instance /var/lib/libvirt/images
 - Script sets up a local lab on the default nat virbr0 network. Assign as required for your deplyment.