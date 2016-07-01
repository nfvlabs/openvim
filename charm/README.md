# Juju Charms for deploying OpenVIM

## Overview
These are the charm layers used to build Juju charms for deploying OpenVIM components. These charms are also published to the [Juju Charm Store](https://jujucharms.com/) and can be deployed directly from there using the [etsi-osm](https://jujucharms.com/u/nfv/etsi-osm), or they can be build from these layers and deployed locally.

## Building the OpenVIM Charms

To build these charms, you will need [charm-tools][]. You should also read
over the developer [Getting Started][] page for an overview of charms and
building them. Then, in any of the charm layer directories, use `charm build`.
For example:

    export JUJU_REPOSITORY=$HOME/charms
    mkdir $HOME/charms

    cd openvim/charms/hadoop/layer-openvim
    charm build

This will build the OpenVIM controller charm, pulling in the appropriate base and
interface layers from [interfaces.juju.solutions][]. You can get local copies
of those layers as well using `charm pull-source`:

    export LAYER_PATH=$HOME/layers
    export INTERFACE_PATH=$HOME/interfaces
    mkdir $HOME/{layers,interfaces}

    charm pull-source layer:openvim-compute
    charm pull-source interface:openvim-compute

You can then deploy the locally built charms individually:

    juju deploy local:exenial/openvim

You can also use the local version of a bundle:

    juju deploy openvim/charms/bundles/openmano.yaml

> Note: With Juju versions < 2.0, you will need to use [juju-deployer][] to
deploy the local bundle.


[charm-tools]: https://jujucharms.com/docs/stable/tools-charm-tools
[Getting Started]: https://jujucharms.com/docs/devel/developer-getting-started
[interfaces.juju.solutions]: http://interfaces.juju.solutions/
[juju-deployer]: https://pypi.python.org/pypi/juju-deployer/
