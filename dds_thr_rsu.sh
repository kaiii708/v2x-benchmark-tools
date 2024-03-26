#!/usr/bin/env bash

set -e #If error occurs, stop the program immediately.

trap "trap - TERM && kill -- -$$" INT TERM EXIT

experiment_name=$1
shift
option=$1
shift
distance=$1
shift
timer=$1
shift
payload_size=$1
shift
remote_cyclonedds_path=$1
shift

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd ${script_dir}

mkdir -p ./rsu_log/${experiment_name}/dds_throughput/${option}/${distance}m
cd ./rsu_log/${experiment_name}/dds_throughput/${option}/${distance}m

export LD_LIBRARY_PATH=$HOME/${remote_cyclonedds_path}/lib
$HOME/${remote_cyclonedds_path}/bin/ddsperf sub -D $((${timer}+5)) > ./${payload_size}.txt 2>./${payload_size}_err.txt

if [ ! -s "${payload_size}_err.txt" ];then
    rm ${payload_size}_err.txt
fi