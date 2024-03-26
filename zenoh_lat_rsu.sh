#!/usr/bin/env bash

set -e #If error occurs, stop the program immediately.

#TODO:cleanup empty err message file
trap "trap - SIGTERM && kill -- -$$" INT TERM EXIT

experiment_name=$1
shift
option=$1
shift
distance=$1
shift
port_on_rsu=$1
shift
remote_zenoh_path=$1
shift

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd ${script_dir}
# echo "$$" > ./rsu_script_pid.txt

mkdir -p ./rsu_log/${experiment_name}/zenoh_latency
cd ./rsu_log/${experiment_name}/zenoh_latency
"$HOME/${remote_zenoh_path}/target/release/examples/z_pong" -l tcp/0.0.0.0:${port_on_rsu}
2>./"${option}_${distance}m_err.txt"

if [ ! -s "${option}_${distance}m_err.txt" ];then
    rm "${option}_${distance}m_err.txt"
fi