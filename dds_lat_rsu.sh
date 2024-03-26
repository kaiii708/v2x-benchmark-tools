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
remote_cyclonedds_path=$1
shift

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd ${script_dir}

mkdir -p ./rsu_log/${experiment_name}/dds_latency
cd ./rsu_log/${experiment_name}/dds_latency

export LD_LIBRARY_PATH=$HOME/${remote_cyclonedds_path}/lib
$HOME/${remote_cyclonedds_path}/bin/ddsperf pong -D $((${timer}+5)) > ./${option}_${distance}m.txt 2>./${option}_${distance}m_err.txt

if [ ! -s "${option}_${distance}m_err.txt" ];then
    rm "${option}_${distance}m_err.txt"
fi
