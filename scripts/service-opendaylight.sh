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

#launch opendaylight inside a screen. It assumes shell variable $OPENDAYLIGHT_PATH
# contain the installation path


DIRNAME=$(readlink -f ${BASH_SOURCE[0]})
DIRNAME=$(dirname $DIRNAME )
DIR_OM=$(dirname $DIRNAME )

function usage(){
    echo -e "Usage: $0 start|stop|restart|status"
    echo -e "  Launch|Removes|Restart|Getstatus opendaylight on a screen"
    echo -e "  Shell variable OPENDAYDLIGHT_PATH must indicate opendaylight installation path"
}

function kill_pid(){
    #send TERM signal and wait 5 seconds and send KILL signal ir still running
    #PARAMS: $1: PID of process to terminate
    kill $1 #send TERM signal
    WAIT=5
    while [ $WAIT -gt 0 ] && ps -o pid -U $USER -u $USER | grep -q $1
    do
        sleep 1
        WAIT=$((WAIT-1))
        [ $WAIT -eq 0 ] && echo -n "sending SIGKILL...  " &&  kill -9 $1  #kill when count reach 0
    done
    echo "done"
   
}

#obtain parameters
#om_action="start"  #uncoment to get a default action
for param in $*
do
    [ "$param" == "start" -o "$param" == "stop"  -o "$param" == "restart" -o "$param" == "status" ] && om_action=$param  && continue
    [ "$param" == "openflow" -o "$param" == "flow" -o "$param" == "opendaylight" ] && continue
    [ "$param" == "-h" -o "$param" == "--help" ] && usage && exit 0
    
    #if none of above, reach this line because a param is incorrect
    echo "Unknown param '$param' type $0 --help" >&2
    exit -1
done

#check action is provided
[ -z "$om_action" ] && usage >&2 && exit -1

    om_cmd="./karaf"
    om_name="opendaylight"
    
    #obtain PID of program
    component_id=`ps -o pid,cmd -U $USER -u $USER | grep -v grep | grep ${om_cmd} | awk '{print $1}'`

    #status
    if [ "$om_action" == "status" ]
    then
        [ -n "$component_id" ] && echo "    $om_name running, pid $component_id"
        [ -z "$component_id" ] && echo "    $om_name stopped"
    fi

    #stop
    if [ "$om_action" == "stop" -o "$om_action" == "restart" ]
    then
        #terminates program
        [ -n "$component_id" ] && echo -n "    stopping $om_name ... " && kill_pid $component_id 
        component_id=""
        #terminates screen
        if screen -wipe | grep -Fq .flow
        then
            screen -S flow -p 0 -X stuff "exit\n"
            sleep 1
        fi
    fi

    #start
    if [ "$om_action" == "start" -o "$om_action" == "restart" ]
    then
        [[ -z $OPENDAYDLIGHT_PATH ]] && echo "OPENDAYDLIGHT_PATH shell variable must indicate opendaylight installation path" >&2 && exit -1
        #calculates log file name
        logfile=""
        mkdir -p $DIR_OM/logs && logfile=$DIR_OM/logs/openflow.log && logfile_console=$DIR_OM/logs/openflow_console.log || echo "can not create logs directory  $DIR_OM/logs"
        #check already running
        [ -n "$component_id" ] && echo "    $om_name is already running. Skipping" && continue
        #create screen if not created
        echo -n "    starting $om_name ... "
        if ! screen -wipe | grep -Fq .flow
        then
            pushd ${OPENDAYDLIGHT_PATH}/bin > /dev/null
            screen -dmS flow  bash
            sleep 1
            popd > /dev/null
        else
            echo -n " using existing screen 'flow' ... "
            screen -S flow -p 0 -X log off
            screen -S flow -p 0 -X stuff "cd ${OPENDAYDLIGHT_PATH}/bin\n"
            sleep 1
        fi
        #move old log file index one number up and log again in index 0
        if [[ -n $logfile ]]
        then
            for index in .9 .8 .7 .6 .5 .4 .3 .2 .1 ""
            do
                rm -f ${logfile}${index}
                ln -s ${OPENDAYDLIGHT_PATH}/data/log/karaf.log${index} ${logfile}${index}
            done
            rm -rf ${logfile_console}
            screen -S flow -p 0 -X logfile ${logfile_console}
            screen -S flow -p 0 -X log on
        fi
        #launch command to screen
        screen -S flow -p 0 -X stuff "${om_cmd}\n"
        #check if is running
        [[ -n $logfile ]] && timeout=120 #2 minute
        [[ -z $logfile ]] && timeout=20
        while [[ $timeout -gt 0 ]]
        do
           #check if is running
           #echo timeout $timeout
           #if !  ps -f -U $USER -u $USER | grep -v grep | grep -q ${om_cmd}
           log_lines=0
           [[ -n $logfile_console ]] && log_lines=`head ${logfile_console} | wc -l`
           component_id=`ps -o pid,cmd -U $USER -u $USER | grep -v grep | grep ${om_cmd} | awk '{print $1}'`
           if [[ -z $component_id ]]
           then #process not started or finished
               [[ $log_lines -ge 2 ]] &&  echo -n "ERROR, it has exited." && break
               #started because writted serveral lines at log so report error
           fi
           [[ -n $logfile_console ]] && grep -q "Listening on port" ${logfile_console} && sleep 1 && break
           sleep 1
           timeout=$((timeout -1))
        done
        if [[ -n $logfile_console ]] && [[ $timeout == 0 ]] 
        then 
           echo -n "timeout!"
        else
           echo -n "running on 'screen -x flow'."
        fi
        [[ -n $logfile ]] && echo "  Logging at '${logfile}'" || echo
    fi




