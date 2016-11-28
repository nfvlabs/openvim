_**This page is obsolete.**_

_**The project OpenVIM, as well as OpenMANO, has been contributed to the open source community project Open Source MANO (OSM), hosted by ETSI.**_

_**Go to the URL [osm.etsi.org](osm.etsi.org) to know more about OSM.**_

***

# openvim
Openvim is a light implementation of an NFV VIM supporting EPA features and control of an underlay switching infrastructure through an OFC. Some of the EPA features included in openvim are:
- CPU pinning
- Memory pinning
- NUMA pinning
- Support of memory huge pages
- Port passthrough interfaces
- SR-IOV interfaces
- Injection of virtual PCI addresses

Openvim interfaces with the compute nodes in the NFV Infrastructure and an Openflow controller in order to provide computing and networking capabilities and to deploy virtual machines. It offers a northbound interface, based on REST ([openvim API](http://github.com/nfvlabs/openvim/raw/master/docs/openvim-api-0.6.pdf "openvim API")), where enhanced cloud services are offered including the creation, deletion and management of images, flavors, instances and networks. 

#History

Openvim was originally part of OpenMANO, an open source project providing a practical implementation of an ETSI MANO stack: a VIM (openvim), and NFVO+VNFM (openmano) and a GUI (openmano-gui). With the creation of ETSI Open Source MANO (OSM), the NFVO+VNFM (openmano) was contributed to OSM as seed code. From OSM Release 1, the VIM (openvim) has also been contributed to OSM. Openvim is maintained now by OSM, and this repository will be kept as fall-back. The up-to-date repo of openvim is located at [OSM openvim repo](https://osm.etsi.org/gitweb/?p=osm/openvim.git;a=summary)

#Releases

The relevant releases/branches in openvim are the following:

- **v0.4**: current stable release for normal use.
- **master**: development branch intended for contributors, with new features that will be incorporated into the stable release

#Quick installation of current release (v0.4)

- Download e.g. a [Ubuntu Server 14.04 LTS](http://virtualboxes.org/images/ubuntu-server) (ubuntu/reverse). Other tested distributions are [Ubuntu Desktop 64bits 14.04.2 LTS](http://sourceforge.net/projects/osboxes/files/vms/vbox/Ubuntu/14.04/14.04.2/Ubuntu_14.04.2-64bit.7z/download) (osboxes/osboxes.org), [CentOS 7](http://sourceforge.net/projects/osboxes/files/vms/vbox/CentOS/CentOS_7-x86_64.7z/download) (osboxes/osboxes.org)
- Start the VM and execute the following command in a terminal:

        wget https://github.com/nfvlabs/openvim/raw/v0.4/scripts/install-openvim.sh
        chmod +x install-openvim.sh
        sudo ./install-openvim.sh [<database-root-user> [<database-root-password>]]
        #NOTE: you can provide optionally the DB root user and password.

Manual installation can be done following these [instructions](https://github.com/nfvlabs/openvim/wiki/Getting-started#manual-installation). 

#Full documentation
- [Getting started](https://github.com/nfvlabs/openvim/wiki/Getting-started "getting started")
- [Compute node configuration](https://github.com/nfvlabs/openvim/wiki/Compute-node-configuration "compute node configuration")
- [Openvim usage manual](https://github.com/nfvlabs/openvim/wiki/openvim-usage  "openvim usage manual")
- [Openvim API](https://github.com/nfvlabs/openvim/raw/master/docs/openvim-api-0.6.pdf "openvim API")

#License
Check the [License](https://github.com/nfvlabs/openvim/blob/master/LICENSE "license") file.

#Contact
For bug reports or clarification, contact [nfvlabs@tid.es](mailto:nfvlabs@tid.es "nfvlabs")

