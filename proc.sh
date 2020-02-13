#!/bin/bash

logdir=$1
: ${logdir:=.}

# port=$1  #获取进程port
ports=(22 80 8080)
cmds=(client_bc redis java dockerd zookeeper kafka orderer peer nginx)
#获取进程pid

hostname=`hostname`
step=10
olddate=`date +%Y%m%d`

###
# use crontab instead of using `sleep` command in script especially when you want to use a shorter step
# replace your path that store this script into ${PATH} 
# sleep time in crontab depends on your step defined in this script
#
# crontab -e
#
# * * * * * /bin/bash ${PATH}/proc.sh
# * * * * * sleep 10; /bin/bash ${PATH}/proc.sh
# * * * * * sleep 20; /bin/bash ${PATH}/proc.sh
# * * * * * sleep 30; /bin/bash ${PATH}/proc.sh
# * * * * * sleep 40; /bin/bash ${PATH}/proc.sh
# * * * * * sleep 50; /bin/bash ${PATH}/proc.sh
###

function send(){
    tags=$1  # port=$port   cmdline=$cmd
    pid=$2
    ts=`date +%s`

    cpu=`ps --no-heading --pid=$pid -o pcpu|sed s/[[:space:]]//g`                       #获取cpu占用    
    ios=`cat /proc/$pid/io`
    ioin=`echo "$ios"|grep read_bytes|awk '{print $2}'`                                 #获取io输入
    ioout=`echo "$ios"|grep -v cancelled_write_bytes|grep write_bytes|awk '{print $2}'` #获取io输出
    mem=`cat /proc/$pid/status|grep -e VmRSS| awk '{print $2}'`                         #获取内存
    if [ "$mem" == "" ];then
        mem=0
    fi
    mem=$[ $mem * 1024 ]
    metrics="[{\"endpoint\":\"$hostname\",\"metric\":\"proc.cpu\",\"value\":$cpu,\"step\":$step,\"counterType\":\"GAUGE\",\"timestamp\":$ts,\"tags\":\"${tags}\"}","{\"endpoint\":\"$hostname\",\"metric\":\"proc.mem\",\"value\":$mem,\"step\":$step,\"counterType\":\"GAUGE\",\"timestamp\":$ts,\"tags\":\"${tags}\"}","{\"endpoint\":\"$hostname\",\"metric\":\"proc.io.in\",\"value\":$ioin,\"step\":$step,\"counterType\":\"GAUGE\",\"timestamp\":$ts,\"tags\":\"${tags}\"}","{\"endpoint\":\"$hostname\",\"metric\":\"proc.io.out\",\"value\":$ioout,\"step\":$step,\"counterType\":\"GAUGE\",\"timestamp\":$ts,\"tags\":\"${tags}\"}]"
    
    
    newdate=`date +%Y%m%d`
    if [ $newdate != $olddate ];then
        mv ${logdir}/proc.log ${logdir}/proc${olddate}.log
        olddate=$newdate
    fi
    echo $metrics >> ${logdir}/proc.log

    curl -X POST -d $metrics  http://192.168.29.244:1988/v1/push
    echo
}

    for p in ${ports[@]}; do
        pid=`netstat -anp | grep ":$p " | grep LISTEN| awk '{print $7}' | awk -F"/" '{ print $1 }'|uniq`
        if [ "$pid" != "" ]; then
            echo port=$p $pid
            send port=$p $pid
        fi
    done
    
    for cmd in ${cmds[@]}; do
        pids=`ps -ef|grep $cmd|grep -v docker-containerd|grep -v grep|awk '{print $2}'|tr -s '\n' ' '`
        if [ "$pids" == "" ];then
            continue
        fi
        
        for pid in ${pids[@]};do
            echo pid=$pid,cmdline=$cmd "$pid"
            send pid=$pid,cmdline=$cmd "$pid"
        done
    done

