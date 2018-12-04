#!/bin/bash

# cd $falcon/custom && bash cmd.sh stop && svn checkout svn://192.168.31.103:6500/open-falcon/plugins $falcon/custom && cd $falcon/custom && bash cmd.sh start

LOG_DIR=/bgi/logs/open-falcon
mkdir -p $LOG_DIR

scripts=(du.sh top.sh proc.sh)

function start(){
    arr=$@
    if [ "$arr" == "" ];then
        arr=${scripts[@]}
    fi

    for sh in ${arr[@]};do
        echo start $sh
        nohup bash $sh $LOG_DIR &
        sleep 1
    done
}

function stop(){
    arr=$@
    if [ "$arr" == "" ];then
        arr=${scripts[@]}
    fi

    # echo ${arr[@]}
    for sh in ${arr[@]};do
        pids=$(ps -aux|grep -v grep|grep -v cmd.sh|grep "$sh"|awk '{print $2}'|tr -s '\n' ' ')
        echo stop $sh $pids
        kill -9 $pids
    done
}

$@