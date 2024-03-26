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
timer=$1
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

mkdir -p ./car_log/${experiment_name}/dds_throughput/${option}/${distance}m
cd ./car_log/${experiment_name}/dds_throughput/${option}/${distance}m

for PAYLOAD_SIZE in ${payload_size_list[@]};
do
    ssh -f "${rsu_user}@${rsu_ip}" ./benchmark-script/dds_thr_rsu.sh ${experiment_name} ${option} ${distance} ${timer} ${PAYLOAD_SIZE} ${remote_cyclonedds_path}

    echo "running ddsperf publish, payload_size:${PAYLOAD_SIZE}"
    
    ${local_cyclonedds_path}/bin/ddsperf pub size ${PAYLOAD_SIZE} -D ${timer} > >(tee ./${PAYLOAD_SIZE}.txt) 2> >(tee ./${PAYLOAD_SIZE}_err.txt >&2)
    #TODO: ddsperf pub sub duration
    if [ ! -s "${PAYLOAD_SIZE}_err.txt" ];then
        rm ${PAYLOAD_SIZE}_err.txt
    fi
done
