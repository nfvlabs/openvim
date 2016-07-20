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

#This script can be used as a basic test of openvim 
#stopping on an error
#WARNING: It destroy the database content


function usage(){
    echo -e "usage: ${BASH_SOURCE[0]} [OPTIONS] <action>\n  Deletes openvim content and add fake hosts, networks"
    echo -e "  <action> is a list of the following items (by default 'reset create')"
    echo -e "    reset     reset the openvim database content"
    echo -e "    create    creates fake hosts and networks"
    echo -e "    delete    delete created items"
    echo -e "    delete-all delete vms. flavors, images, ..."
    echo -e "  OPTIONS:"
    echo -e "    -f --force : does not prompt for confirmation"
    echo -e "    -d --delete : same to action delete-all"
    echo -e "    --insert-bashrc  insert the created tenant variables at"
    echo -e "                     ~/.bashrc to be available by openvim CLI"
    echo -e "    -h --help  : shows this help"
}

function is_valid_uuid(){
    echo "$1" | grep -q -E '^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$' && return 0
    return 1
}


#detect if is called with a source to use the 'exit'/'return' command for exiting
[[ ${BASH_SOURCE[0]} != $0 ]] && _exit="return" || _exit="exit"

#check correct arguments
force=""
action_list=""
insert_bashrc=""

while [[ $# -gt 0 ]]
do
    argument="$1"
    shift
    if [[ $argument == reset ]] || [[ $argument == create ]] || [[ $argument == delete ]] || [[ $argument == delete-all ]]
    then
        action_list="$action_list $argument"
        continue
    #short options
    elif [[ ${argument:0:1} == "-" ]] && [[ ${argument:1:1} != "-" ]] && [[ ${#argument} -ge 2 ]]
    then
        index=0
        while index=$((index+1)) && [[ $index -lt ${#argument} ]]
        do
            [[ ${argument:$index:1} == h ]]  && usage   && $_exit 0
            [[ ${argument:$index:1} == f ]]  && force=y && continue
            [[ ${argument:$index:1} == d ]]  && action_list="delete-all $action_list" && continue
            echo "invalid option '${argument:$index:1}'?  Type -h for help" >&2 && $_exit 1
        done
        continue
    fi
    #long options
    [[ $argument == --help ]]   && usage   && $_exit 0
    [[ $argument == --force ]]  && force=y && continue
    [[ $argument == --delete ]] && action_list="delete-all $action_list" && continue
    [[ $argument == --insert-bashrc ]] && insert_bashrc=y && continue
    echo "invalid argument '$argument'?  Type -h for help" >&2 && $_exit 1
done

DIRNAME=$(dirname $(readlink -f ${BASH_SOURCE[0]}))
DIRvim=$(dirname $DIRNAME)
export OPENVIM_HOST=localhost
export OPENVIM_PORT=9080
[[ $insert_bashrc == y ]] && echo -e "\nexport OPENVIM_HOST=localhost"  >> ~/.bashrc
[[ $insert_bashrc == y ]] && echo -e "\nexport OPENVIM_PORT=9080"  >> ~/.bashrc
#by default action should be reset and create
[[ -z $action_list ]]  && action_list="reset create"


for action in $action_list
do
if [[ $action == "reset" ]]
then
    #ask for confirmation if argument is not -f --force
    force_="y"
    [[ $force  != y ]] && read -e -p "WARNING: openvim database content will be lost!!!  Continue(y/N)" force_
    [[ $force_ != y ]] && [[ $force_ != yes ]] && echo "aborted!" && $_exit
    echo "deleting deployed vm"
    ${DIRvim}/openvim vm-delete -f | grep -q deleted && sleep 10 #give some time to get virtual machines deleted
    echo "Stopping openvim"
    $DIRNAME/service-openvim.sh stop
    echo "Initializing databases"
    $DIRvim/database_utils/init_vim_db.sh -u vim -p vimpw
    echo "Starting openvim"
    $DIRNAME/service-openvim.sh start

elif [[ $action == delete-all ]] 
then
    for t in `${DIRvim}/openvim tenant-list | awk '/^ *[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12} +/{printf("%s:%s",$1,$2)}'`
    do
        t_id=${t%%:*}
        t_name=${t#*:}
        [[ -z $t_id ]] && continue 
        export OPENVIM_TENANT=${t_id}
        for what in vm image flavor port net
        do
            items=`${DIRvim}/openvim $what-list | awk '/^ *[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12} +/{print $1}'`
            if [[ -n $items ]]
            then 
                [[ $force == y ]] && echo deleting openvim ${what}s from tenant ${t_name}
                [[ $force != y ]] && read -e -p "Delete openvim ${what}s from tenant ${t_name}?(y/N) " force_
                [[ $force_ != y ]] && [[ $force_ != yes ]] && echo "aborted!" && $_exit
                for item in $items
                do
                    echo -n "$item   "
                    ${DIRvim}/openvim $what-delete -f $item  || ! echo "fail" >&2 || $_exit 1
                done
            fi
        done
        ${DIRvim}/openvim tenant-delete -f $t_id  || ! echo "fail" >&2 || $_exit 1
        for what in host
        do
            items=`${DIRvim}/openvim $what-list | awk '/^ *[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12} +/{print $1}'`
            if [[ -n $items ]]
            then
                [[ $force == y ]] && echo deleting openvim ${what}s
                [[ $force != y ]] && read -e -p "Delete openvim ${what}s?(y/N) " force_
                [[ $force_ != y ]] && [[ $force_ != yes ]] && echo "aborted!" && $_exit
                for item in $items
                do
                    echo -n "$item   "
                    ${DIRvim}/openvim $what-delete -f $item  || ! echo "fail" >&2 || $_exit 1
                done
            fi
        done

    done
elif [[ $action == "delete" ]]
then
    ${DIRvim}/openvim net-delete -f default           || echo "fail"
    ${DIRvim}/openvim net-delete -f macvtap:em1       || echo "fail"
    ${DIRvim}/openvim net-delete -f shared_bridge_net || echo "fail"
    ${DIRvim}/openvim net-delete -f data_net          || echo "fail"
    ${DIRvim}/openvim host-remove -f fake-host-0      || echo "fail"
    ${DIRvim}/openvim host-remove -f fake-host-1      || echo "fail"
    ${DIRvim}/openvim host-remove -f fake-host-2      || echo "fail"
    ${DIRvim}/openvim host-remove -f fake-host-3      || echo "fail"
    result=`openvim tenant-list TEST-admin`
    vimtenant=`echo $result |gawk '{print $1}'`
    #check a valid uuid is obtained
    is_valid_uuid $vimtenant || ! echo "Tenant TEST-admin not found. Already delete?" >&2 || $_exit 1
    export OPENVIM_TENANT=$vimtenant
    ${DIRvim}/openvim tenant-delete -f TEST-admin     || echo "fail"
    echo

elif [[ $action == "create" ]]
then
    echo "Adding example hosts"
    ${DIRvim}/openvim host-add $DIRvim/test/hosts/host-example0.json || ! echo "fail" >&2 || $_exit 1
    ${DIRvim}/openvim host-add $DIRvim/test/hosts/host-example1.json || ! echo "fail" >&2 || $_exit 1
    ${DIRvim}/openvim host-add $DIRvim/test/hosts/host-example2.json || ! echo "fail" >&2 || $_exit 1
    ${DIRvim}/openvim host-add $DIRvim/test/hosts/host-example3.json || ! echo "fail" >&2 || $_exit 1
    echo "Adding example nets"
    ${DIRvim}/openvim net-create $DIRvim/test/networks/net-example0.yaml || ! echo "fail" >&2 || $_exit 1
    ${DIRvim}/openvim net-create $DIRvim/test/networks/net-example1.yaml || ! echo "fail" >&2 || $_exit 1
    ${DIRvim}/openvim net-create $DIRvim/test/networks/net-example2.yaml || ! echo "fail" >&2 || $_exit 1
    ${DIRvim}/openvim net-create $DIRvim/test/networks/net-example3.yaml || ! echo "fail" >&2 || $_exit 1

    printf "%-50s" "Creating openvim tenant 'TEST-admin': "
    result=`openvim tenant-create '{"tenant": {"name":"TEST-admin", "description":"admin"}}'`
    vimtenant=`echo $result |gawk '{print $1}'`
    #check a valid uuid is obtained
    ! is_valid_uuid $vimtenant && echo "FAIL" && echo "    $result" && $_exit 1
    echo "  $vimtenant"
    export OPENVIM_TENANT=$vimtenant
    [[ $insert_bashrc == y ]] && echo -e "\nexport OPENVIM_TENANT=$vimtenant" >> ~/.bashrc

    echo
    #echo "Check virtual machines are deployed"
    #vms_error=`openvim vm-list | grep ERROR | wc -l`
    #vms=`openvim vm-list | wc -l`
    #[[ $vms -ne 8 ]]       &&  echo "WARNING: $vms VMs created, must be 8 VMs" >&2 && $_exit 1
    #[[ $vms_error -gt 0 ]] &&  echo "WARNING: $vms_error VMs with ERROR" >&2       && $_exit 1
fi
done

echo
echo DONE
#echo "Listing VNFs"
#openvim vnf-list
#echo "Listing scenarios"
#openvim scenario-list
#echo "Listing scenario instances"
#openvim instance-scenario-list


