# Overview

Launches an OpenVIM controller.

# Preparation

When running with an LXD cloud, the openvim-compute nodes needs to have some
devices added and be run with extra privileges. A quick-and-dirty way of
accomplishing this is to edit the juju-default LXD profile:

    lxc profile edit juju-default
    
change it to:

    name: juju-default
    config:
      boot.autostart: "true"
      security.nesting: "true"
      security.privileged: "true"
    description: ""
    devices:
      kvm:
        path: /dev/kvm
        type: unix-char
      tun:
        path: /dev/net/tun
        type: unix-char

# Usage

    juju deploy mysql
    juju deploy openvim
    juju deploy openvim-compute
    juju relate mysql openvim
    juju relate openvim-compute openvim
    
# Creating and starting a VM

The openvim charm will create a default tenant, image, flavor,
and networks, but you'll want to add your own VM when you're ready to deploy.
This charm generates a basic VM yaml definition for you if you'd like to launch
one quickly. First, ssh into your openvim box:

    juju ssh openvim-contrller/0 # may not be zero, find instance id with `juju status`.

Then create your VM and get its uuid:

    /home/ubuntu/openmano/openvim/openvim vm-create /tmp/server.yaml
    
And finally start it:

    /home/ubuntu/openmano/openvim/openvim vm-start <vm-uuid>
    

# Contact Information

Rye Terrell rye.terrell@canonical.com
George Kraft george.kraft@canonical.com
