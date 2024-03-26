#!/usr/bin/env bash

set -e

trap "trap - TERM && kill -- -$$" INT TERM EXIT

experiment_name=$1
shift
option=$1
shift
distance=$1
shift
timer=$1
shift
port_on_rsu=$1
shift

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd ${script_dir}

mkdir -p ./rsu_log/${experiment_name}/throughput
cd ./rsu_log/${experiment_name}/throughput

iperf3 -s -p ${port_on_rsu} -1 > ./${option}_${distance}m.txt 2>./${option}_${distance}m_err.txt

if [ ! -s "${option}_${distance}m_err.txt" ];then
    rm "${option}_${distance}m_err.txt"
fi