#!/bin/bash

BENCHMARK=SSSP
NAME=sssp

echo "Preparing results, please wait."

run_benchmark() {
  dataset=$1
  dataset_path=$2
  aggregation_version=$3
  threshold_value=$4
  coarsening_value=$5
  cdp_t_c_threshold_value=$6
  cdp_t_c_coarsening_value=$7

  cdp_t_a_aggregation_version=$8
  cdp_t_a_threshold_value=$9

  cdp_c_a_aggregation_version=${10}
  cdp_c_a_coarsening_value=${11}

  cdp_t_c_a_aggregation_version=${12}
  cdp_t_c_a_threshold_value=${13}
  cdp_t_c_a_coarsening_value=${14}

  docker exec -it klap bash -c "cd /klap/test/${BENCHMARK} && make COARSE_FACTOR=${coarsening_value} THRESHOLD_T=${threshold_value} -s -B -j ${NAME}.cdp ${NAME}.nocdp ${NAME}.${aggregation_version} ${NAME}.tcdp ${NAME}.ccdp1" > /dev/null 2>&1
  cdp_average=$(./${NAME}.cdp -f "${dataset_path}" -o0)
  no_cdp_average=$(./${NAME}.nocdp -f "${dataset_path}" -o0)
  aggregation_average=$(./${NAME}.${aggregation_version} -f "${dataset_path}" -o0)
  threshold_average=$(./${NAME}.tcdp -f "${dataset_path}" -o0)
  coarsening_average=$(./${NAME}.ccdp1 -f "${dataset_path}" -o0)

  docker exec -it klap bash -c "cd /klap/test/${BENCHMARK} && make COARSE_FACTOR=${cdp_t_c_coarsening_value} THRESHOLD_T=${cdp_t_c_threshold_value} -s -B -j ${NAME}.ctcdp1" > /dev/null 2>&1
  cdp_t_c_average=$(./${NAME}.ctcdp1 -f "${dataset_path}" -o0)

  docker exec -it klap bash -c "cd /klap/test/${BENCHMARK} && make THRESHOLD_T=${cdp_t_a_threshold_value} -s -j ${NAME}.${cdp_t_a_aggregation_version}" > /dev/null 2>&1
  cdp_t_a_average=$(./${NAME}.${cdp_t_a_aggregation_version} -f "${dataset_path}" -o0)


  docker exec -it klap bash -c "cd /klap/test/${BENCHMARK} && make COARSE_FACTOR=${cdp_c_a_coarsening_value} -s -B -j ${NAME}.${cdp_c_a_aggregation_version}" > /dev/null 2>&1
  cdp_c_a_average=$(./${NAME}.${cdp_c_a_aggregation_version} -f "${dataset_path}" -o0)

  docker exec -it klap bash -c "cd /klap/test/${BENCHMARK} && make COARSE_FACTOR=${cdp_t_c_a_coarsening_value} THRESHOLD_T=${cdp_t_c_a_threshold_value} -s -B -j ${NAME}.${cdp_t_c_a_aggregation_version}" > /dev/null 2>&1
  cdp_t_c_a_average=$(./${NAME}.${cdp_t_c_a_aggregation_version} -f "${dataset_path}" -o0)


  echo "${NAME}, ${dataset}, ${no_cdp_average}, ${cdp_average}, ${aggregation_average}, ${threshold_average}, ${coarsening_average}, ${cdp_t_c_average}, ${cdp_t_a_average}, ${cdp_c_a_average} , ${cdp_t_c_a_average}" >> best.csv
}

echo "benchmark, dataset, NOCDP, CDP, CDP + A, CDP + T, CDP + C, CDP + T + C, CDP + T + A, CDP + C + A ,CDP + T + C + A" > best.csv
run_benchmark "KRON" "../../datasets/kron_g500-simple-logn16.gr" "ag" 1024 512 1024 512 "tag" 512 "cag1" 16 "ctag1" 128 2
run_benchmark "CNR" "../../datasets/cnr-2000.gr" "ag" 1024 16 1024 8 "tag" 128 "cag1" 8 "ctag1" 128 256
run_benchmark "ROAD-NY" "../../datasets/USA-road-d-NY.gr" "ag" 1024 32 1024 2048 "taw" 1024 "cag1" 128 "ctaw" 32 512
echo "generated best.csv"

