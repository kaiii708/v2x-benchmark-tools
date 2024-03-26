#!/usr/bin/env bash

set -e
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

mkdir -p ./car_log/${experiment_name}/dds_latency
cd ./car_log/${experiment_name}/dds_latency

ssh -f "${rsu_user}@${rsu_ip}" ./benchmark-script/dds_lat_rsu.sh ${experiment_name} ${option} ${distance} ${timer} ${remote_cyclonedds_path}
sleep 1 #ensure that the server starts before the client

${local_cyclonedds_path}/bin/ddsperf ping -D ${timer} > >(tee ./${option}_${distance}m.txt) 2> >(tee ./${option}_${distance}m_err.txt >&2)

if [ ! -s ${option}_${distance}m_err.txt ];then
    rm ${option}_${distance}m_err.txt
fi
