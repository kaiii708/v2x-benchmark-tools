#!/usr/bin/env bash

# If error occurs, stop the program immediately.
set -e

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

mkdir -p ./car_log/${experiment_name}/zenoh_throughput/${option}/${distance}m
cd ./car_log/${experiment_name}/zenoh_throughput/${option}/${distance}m

# Create remote tmux session
ssh "${rsu_user}@${rsu_ip}" tmux new-session -d -s zenoh

for PAYLOAD_SIZE in ${payload_size_list[@]};
do
    ssh -f "${rsu_user}@${rsu_ip}" tmux send -t zenoh "~/zenoh/target/release/examples/z_pub_thr \ ${PAYLOAD_SIZE} \ -l \ tcp/0.0.0.0:8888" ENTER
    sleep 1

    echo "running zenoh publish, payload_size:${PAYLOAD_SIZE}"
    
    ${local_zenoh_path}/target/release/examples/z_sub_thr -e tcp/${rsu_ip}:${port_on_rsu} -n 1000 \
    >./${PAYLOAD_SIZE}.txt 2> >(tee ./${PAYLOAD_SIZE}_err.txt >&2)
    
    if [ ! -s "${PAYLOAD_SIZE}_err.txt" ];then
        rm ${PAYLOAD_SIZE}_err.txt
    fi

    # Stop remote z_pub process.
    ssh -f "${rsu_user}@${rsu_ip}" tmux send -t zenoh ^C 
done

# Kill remote tmux session.
ssh "${rsu_user}@${rsu_ip}" tmux kill-session -t zenoh
