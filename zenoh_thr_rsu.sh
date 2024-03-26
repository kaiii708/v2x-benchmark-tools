#!/usr/bin/env bash

set -e #If error occurs, stop the program immediately.

trap "trap - TERM && kill -- -$$" INT TERM EXIT

experiment_name=$1
shift
option=$1
shift
distance=$1
shift
port_on_rsu=$1
shift
payload_size=$1
shift

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd ${script_dir}

mkdir -p ./rsu_log/${experiment_name}/zenoh_throughput/${option}/${distance}m
cd ./rsu_log/${experiment_name}/zenoh_throughput/${option}/${distance}m

$HOME/zenoh/target/release/examples/z_sub_thr -l tcp/0.0.0.0:${port_on_rsu} \
>./${payload_size}.txt 2>./${payload_size}_err.txt

if [ ! -s "${payload_size}_err.txt" ];then
    rm ${payload_size}_err.txt
fi