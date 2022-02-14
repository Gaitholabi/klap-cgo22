#!/bin/bash

BENCHMARK=TC
NAME=tc

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

  docker exec -it klap bash -c "cd /klap/test/${BENCHMARK} && make COARSE_FACTOR=${coarsening_value} THRESHOLD_T=${threshold_value} -s -B -j ${NAME}.base ${NAME}.${aggregation_version} ${NAME}.ccdp1" > /dev/null 2>&1
  cdp_average=$(./${NAME}.base -g "${dataset_path}" -o0 -b -t 1)
  no_cdp_average=$(./${NAME}.base -g "${dataset_path}" -o0 -d)
  aggregation_average=$(./${NAME}.${aggregation_version} -g "${dataset_path}" -o0 -b -t 1)
  threshold_average=$(./${NAME}.base -g "${dataset_path}" -o0 -b -t ${threshold_value})
  coarsening_average=$(./${NAME}.ccdp1 -g "${dataset_path}" -o0 -t1)

  docker exec -it klap bash -c "cd /klap/test/${BENCHMARK} && make COARSE_FACTOR=${cdp_t_c_coarsening_value} THRESHOLD_T=${cdp_t_c_threshold_value} -s -B -j ${NAME}.ccdp1" > /dev/null 2>&1
  cdp_t_c_average=$(./${NAME}.ccdp1 -g "${dataset_path}" -o0 -t ${cdp_t_c_threshold_value})

  docker exec -it klap bash -c "cd /klap/test/${BENCHMARK} && make THRESHOLD_T=${cdp_t_a_threshold_value} -s -j ${NAME}.${cdp_t_a_aggregation_version}" > /dev/null 2>&1
  cdp_t_a_average=$(./${NAME}.${cdp_t_a_aggregation_version} -g "${dataset_path}" -o0 -t${cdp_t_a_threshold_value})


  docker exec -it klap bash -c "cd /klap/test/${BENCHMARK} && make COARSE_FACTOR=${cdp_c_a_coarsening_value} -s -B -j ${NAME}.${cdp_c_a_aggregation_version}" > /dev/null 2>&1
  cdp_c_a_average=$(./${NAME}.${cdp_c_a_aggregation_version} -g "${dataset_path}" -o0 -t1)

  docker exec -it klap bash -c "cd /klap/test/${BENCHMARK} && make COARSE_FACTOR=${cdp_t_c_a_coarsening_value} THRESHOLD_T=${cdp_t_c_a_threshold_value} -s -B -j ${NAME}.${cdp_t_c_a_aggregation_version}" > /dev/null 2>&1
  cdp_t_c_a_average=$(./${NAME}.${cdp_t_c_a_aggregation_version} -g "${dataset_path}" -o0 -t${cdp_t_c_a_threshold_value})


  echo "${NAME}, ${dataset}, ${no_cdp_average}, ${cdp_average}, ${aggregation_average}, ${threshold_average}, ${coarsening_average}, ${cdp_t_c_average}, ${cdp_t_a_average}, ${cdp_c_a_average} , ${cdp_t_c_a_average}" >> best.csv
}

echo "benchmark, dataset, NOCDP, CDP, CDP + A, CDP + T, CDP + C, CDP + T + C, CDP + T + A, CDP + C + A ,CDP + T + C + A" > best.csv
run_benchmark "KRON" "../../datasets/kron_g500-simple-logn16.tsv" "ab" 8192 1024 8192 64 "ag" 8192 "cag1" 2048 "cag1" 8192 32
run_benchmark "CNR" "../../datasets/cnr-2000.tsv" "ab" 2048 1024 8192 64 "ag" 4096 "cag1" 128 "cag1" 4096 64

run_benchmark "ROAD-NY" "../../datasets/USA-road-d-NY.tsv" "ag" 16 1024 4096 4 "ab" 256 "cag1" 2048 "cab1" 512 512
echo "generated best.csv"

