#!/usr/bin/env bash

set -e #If error occurs, stop the program immediately.

trap "trap - TERM && kill -- -$$" INT TERM EXIT

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd ${script_dir}
source ./config.properties

option=$1
shift
distance=$1
shift

# Units: byte(s)
payload_size_list=(
    1024
    2048
    4096
    8192
    16384
    32768
    65536
    131072
    262144
)

case "${option}" in
	wifi6)
		rsu_ip=${rsu_ip_on_wifi6}
		;;
	4glte)
		rsu_ip=${rsu_ip_on_4glte}
		;;
	*)
		error "Unexpected expression '${option}'"
		;;
esac

mkdir -p ./car_log/${experiment_name}/zenoh_latency/${option}/${distance}m
cd ./car_log/${experiment_name}/zenoh_latency/${option}/${distance}m

# create a tmux session named "zenoh"
ssh "${rsu_user}@${rsu_ip}" tmux new-session -d -s zenoh
ssh "${rsu_user}@${rsu_ip}" tmux send -t zenoh "~/benchmark-script/zenoh_lat_rsu.sh \ ${experiment_name} \ ${option} \ ${distance} \ ${port_on_rsu} \ ${remote_zenoh_path}" ENTER
sleep 1

for PAYLOAD_SIZE in ${payload_size_list[@]};
do
    echo "running zenoh ping, payload_size:${PAYLOAD_SIZE}"
    ${local_zenoh_path}/target/release/examples/z_ping ${PAYLOAD_SIZE} -e tcp/${rsu_ip}:${port_on_rsu} > >(tee ./${PAYLOAD_SIZE}.txt) 2> >(tee ./${PAYLOAD_SIZE}_err.txt >&2)
    
    if [[ ! -s "${PAYLOAD_SIZE}_err.txt" ]];then
        rm ${PAYLOAD_SIZE}_err.txt
    fi
done

# Kill remote tmux session
ssh "${rsu_user}@${rsu_ip}" tmux kill-session -t zenoh