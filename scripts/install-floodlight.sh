#!/bin/bash

##
# Copyright 2015 Telefónica Investigación y Desarrollo, S.A.U.
# This file is part of openmano
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# For those usages not covered by the Apache License, Version 2.0 please
# contact with: nfvlabs@tid.es
##

#ONLY TESTED for Ubuntu 14.10 14.04, CentOS7 and RHEL7
#Get needed packages, to run floodlight

function usage(){
    echo  -e "usage: sudo $0 \n  Install floodlight v0.9 in ./floodlight-0.90"
}

function install_packages(){
    [ -x /usr/bin/apt-get ] && apt-get install -y $*
    [ -x /usr/bin/yum ]     && yum install -y $*   
    
    #check properly installed
    for PACKAGE in $*
    do
        PACKAGE_INSTALLED="no"
        [ -x /usr/bin/apt-get ] && dpkg -l $PACKAGE            &>> /dev/null && PACKAGE_INSTALLED="yes"
        [ -x /usr/bin/yum ]     && yum list installed $PACKAGE &>> /dev/null && PACKAGE_INSTALLED="yes" 
        if [ "$PACKAGE_INSTALLED" = "no" ]
        then
            echo "failed to install package '$PACKAGE'. Revise network connectivity and try again"
            exit -1
       fi
    done
}

#check root privileges and non a root user behind
[ "$1" == "-h" -o "$1" == "--help" ] && usage && exit 0
[ "$USER" != "root" ] && echo "Needed root privileges" >&2 && usage >&2 && exit -1
[ -z "$SUDO_USER" -o "$SUDO_USER" = "root" ] && echo "Must be runned with sudo from a non root user"  >&2 && usage >&2 && exit -1

echo "This script will update repositories and Installing FloodLight."
echo "It will install Java and other packages, that takes a while to download"
read -e -p "Do you agree on download and install FloodLight from http://www.projectfloodlight.org upon the owner license? (y/N)" KK
[[ "$KK" != "y" ]] && [[ "$KK" != "yes" ]] && exit 0

#Discover Linux distribution
#try redhat type
[ -f /etc/redhat-release ] && _DISTRO=$(cat /etc/redhat-release 2>/dev/null | cut  -d" " -f1) 
#if not assuming ubuntu type
[ -f /etc/redhat-release ] || _DISTRO=$(lsb_release -is  2>/dev/null)            
if [ "$_DISTRO" == "Ubuntu" ]
then
    _RELEASE="14"
    if ! lsb_release -rs | grep -q "14."
    then 
        read -e -p "WARNING! Not tested Ubuntu version. Continue assuming a '$_RELEASE' type? (y/N)" KK
        [ "$KK" != "y" -a  "$KK" != "yes" ] && echo "Cancelled" && exit 0
    fi
elif [ "$_DISTRO" == "CentOS" ]
then
    _RELEASE="7" 
    if ! cat /etc/redhat-release | grep -q "7."
    then
        read -e -p "WARNING! Not tested CentOS version. Continue assuming a '_RELEASE' type? (y/N)" KK
        [ "$KK" != "y" -a  "$KK" != "yes" ] && echo "Cancelled" && exit 0
    fi
elif [ "$_DISTRO" == "Red" ]
then
    _RELEASE="7" 
    if ! cat /etc/redhat-release | grep -q "7."
    then
        read -e -p "WARNING! Not tested Red Hat OS version. Continue assuming a '_RELEASE' type? (y/N)" KK
        [ "$KK" != "y" -a  "$KK" != "yes" ] && echo "Cancelled" && exit 0
    fi
else  #[ "$_DISTRO" != "Ubuntu" -a "$_DISTRO" != "CentOS" -a "$_DISTRO" != "Red" ] 
    _DISTRO_DISCOVER=$_DISTRO
    [ -x /usr/bin/apt-get ] && _DISTRO="Ubuntu" && _RELEASE="14"
    [ -x /usr/bin/yum ]     && _DISTRO="CentOS" && _RELEASE="7"
    read -e -p "WARNING! Not tested Linux distribution '$_DISTRO_DISCOVER '. Continue assuming a '$_DISTRO $_RELEASE' type? (y/N)" KK
    [ "$KK" != "y" -a  "$KK" != "yes" ] && echo "Cancelled" && exit 0
fi



echo '
#################################################################
#####               UPDATE REPOSITORIES                     #####
#################################################################'
[ "$_DISTRO" == "Ubuntu" ] && apt-get update -y

[ "$_DISTRO" == "CentOS" -o "$_DISTRO" == "Red" ] && yum check-update -y
[ "$_DISTRO" == "CentOS" -o "$_DISTRO" == "Red" ] && sudo yum repolist

echo '
#################################################################
#####        DOWNLOADING AND CONFIGURE FLOODLIGHT           #####
#################################################################'
    #Install Java JDK and Ant packages at the VM 
    [ "$_DISTRO" == "Ubuntu" ] && install_packages "build-essential default-jdk ant python-dev screen wget" #TODO revise if packages are needed apart from ant
    [ "$_DISTRO" == "CentOS" -o "$_DISTRO" == "Red" ] && install_package "                 ant screen wget"

  #floodlight 0.9
    echo "downloading v0.90 from the oficial page"
    su $SUDO_USER -c 'wget https://github.com/floodlight/floodlight/archive/v0.90.tar.gz'
    su $SUDO_USER -c 'tar xvzf v0.90.tar.gz'
  #floodlight 1.1
    #echo "downloading v1.1 from the oficial page"
    #su $SUDO_USER -c 'wget https://github.com/floodlight/floodlight/archive/v1.1.tar.gz'
    #su $SUDO_USER -c 'tar xvzf v01.1.tar.gz'
    
    #Configure Java environment variables. It is seem that is not needed!!!
    #export JAVA_HOME=/usr/lib/jvm/default-java" >> /home/${SUDO_USER}/.bashr
    #export PATH=$PATH:$JAVA_HOME
    #echo "export JAVA_HOME=/usr/lib/jvm/default-java" >> /home/${SUDO_USER}/.bashrc
    #echo "export PATH=$PATH:$JAVA_HOME" >> /home/${SUDO_USER}/.bashrc

    #Compile floodlight
    pushd ./floodlight-0.90
    #pushd ./floodlight-1.1
    su $SUDO_USER -c 'ant'
    export FLOODLIGHT_PATH=$(pwd)
    popd

echo '
#################################################################
#####        CONFIGURE envioronment                         #####
#################################################################'
#insert into .bashrc
    echo "    inserting FLOODLIGHT_PATH at .bashrc"
    su $SUDO_USER -c "echo 'export FLOODLIGHT_PATH=\"${FLOODLIGHT_PATH}\"'  >> ~/.bashrc"

echo
echo "Done!  you may need to logout and login again for loading the configuration"
echo " If your have installed openvim, run './openvim/scripts/service-floodlight.sh start' for starting floodlight in a screen"



