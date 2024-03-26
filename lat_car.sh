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

# experiment_name="exp1"

# rsu_ip_on_wifi6="192.168.7.1"
# rsu_ip_on_wifi6="140.112.31.243"
# rsu_ip_on_4glte="111.70.22.32"

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

mkdir -p ./car_log/${experiment_name}/latency
cd ./car_log/${experiment_name}/latency

ssh -f "${rsu_user}@${rsu_ip}" timeout $((timer+3)) qperf
qperf -ip 19766 -t ${timer} ${rsu_ip} tcp_lat > >(tee ./${option}_${distance}m.txt) 2> >(tee ./${option}_${distance}m_err.txt >&2)

if [ ! -s ${option}_${distance}m_err.txt ];then
    rm ${option}_${distance}m_err.txt
fi
