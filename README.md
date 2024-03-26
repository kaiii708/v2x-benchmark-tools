# Benchmark Script
This experiment is for end-to-end connection and focuses on iperf, DDS, and Zenoh transmission performance.

## Prerequisite
- Network environment: Wi-Fi6, 4G
- CycloneDDS ([installation guide](https://github.com/eclipse-cyclonedds/cyclonedds))
- Zenoh ([installation guide](https://github.com/eclipse-zenoh/zenoh))

> :warning: **Warning**: It is necessary to ensure that the car endpoint can establish an SSH connection with the RSU endpoint.

> :warning: **Warning**: All operations are executed only on the car's side.

## Check the configuration
- Edit the **config.properties** file and verify that all parameters in the file are correctly configured.

## Iperf experiment
- install iperf3
```bash=
sudo apt install iperf3
```
- measure latency
```bash=
./lat_car.sh <network> <distance> <timeout>
(e.g., ./lat_car.sh wifi6 10 10)

# <network>: wifi6 or 4glte
# <distance>: distance in meters.
# <timeout>: timeout in seconds.

# Tips: Commands in the following sections follow this convention.

# The output data will be under the ' ./car_log/<experiment_name>/latency/ ' directory.
```
- measure throughput
```bash=
./thr_car.sh <network> <distance> <timeout>

# The output data will be under the ' ./car_log/<experiment_name>/throughput/ ' directory.
```

## DDS experiment
- measure latency
```bash=
./dds_lat_car.sh <network> <distance> <timeout>

# The output data will be under the ' ./car_log/<experiment_name>/dds_latency/ ' directory.
```
- measure throughput
```bash=
./dds_thr_car.sh <network> <distance> <timeout>

# The output data will be under the ' ./car_log/<experiment_name>/dds_throughput/<network>/<distance> ' directory.

# The filename represents the payload.
```

## Zenoh experiment
- measure latency
```bash=
./zenoh_lat_car.sh <network> <distance>

# The output data will be under the ' ./car_log/<experiment_name>/zenoh_latency/<network>/<distance> ' directory.

# The filename represents the payload.
```
- measure throughput
```bash=
./zenoh_thr_car.sh <network> <distance>

# The output data will be under the ' ./car_log/<experiment_name>/zenoh_throughput/<network>/<distance> ' directory.

# The filename represents the payload.

# The larger payload experiments will take time.
```
