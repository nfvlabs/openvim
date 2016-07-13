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

#It generates a report for debugging

DIRNAME=$(readlink -f ${BASH_SOURCE[0]})
DIRNAME=$(dirname $DIRNAME )
OVCLIENT=$DIRNAME/../openvim

#get screen log files at the beginning
echo
echo "-------------------------------"
echo "log files"
echo "-------------------------------"
echo
echo "cat $DIRNAME/../logs/openvim.log*"
cat $DIRNAME/../logs/openvim.log*
echo
echo

#get version
echo
echo "-------------------------------"
echo "version"
echo "-------------------------------"
echo "cat $DIRNAME/../openvimd.py|grep ^__version__"
cat $DIRNAME/../openvimd.py|grep ^__version__
echo
echo

#get configuration files
echo "-------------------------------"
echo "Configuration files"
echo "-------------------------------"
echo "cat $DIRNAME/../openvimd.cfg"
cat $DIRNAME/../openvimd.cfg
echo

#get list of items
for verbose in "" "-vvv"
do
  echo "-------------------------------"
  echo "OPENVIM$verbose"
  echo "-------------------------------"
  echo "$OVCLIENT config"
  $OVCLIENT config
  echo "-------------------------------"
  echo "$OVCLIENT tenant-list $verbose"
  $OVCLIENT tenant-list $verbose
  echo "-------------------------------"
  echo "$OVCLIENT host-list $verbose"
  $OVCLIENT host-list $verbose
  echo "-------------------------------"
  echo "$OVCLIENT net-list $verbose"
  $OVCLIENT net-list $verbose
  echo "-------------------------------"
  echo "$OVCLIENT port-list $verbose"
  $OVCLIENT port-list $verbose
  echo "-------------------------------"
  echo "$OVCLIENT flavor-list $verbose"
  $OVCLIENT flavor-list $verbose
  echo "-------------------------------"
  echo "$OVCLIENT image-list $verbose"
  $OVCLIENT image-list $verbose
  echo "-------------------------------"
  echo "$OVCLIENT vm-list $verbose"
  $OVCLIENT vm-list $verbose
  echo "-------------------------------"
  echo

done
echo
