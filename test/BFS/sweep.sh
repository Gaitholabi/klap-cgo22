#!/bin/bash

BENCHMARK=BFS
NAME=bfs
DATASETS=("-g ../../datasets/kron_g500-simple-logn16.graph" "-g ../../datasets/cnr-2000.graph")
RUNS=10
FILE=$NAME.csv

VERSIONS='nocdp cdp aw ab ag'
THRESHOLD_VERSIONS='tcdp taw tab tag'
COARSE_VERSIONS='ccdp1 caw1 cab1 cag1'
THRESHOLD_COARSE_VERSIONS='ctcdp1 ctaw1 ctab1 ctag1'
DYNAMIC_AGG_VERSIONS_ALL='ctdag1'
COARSE_LIMIT=2048
THRESHOLD_LIMIT=16384
AGGREGATION_LIMIT=256

docker exec -it klap bash -c "cd /klap/test/${BENCHMARK}/ && make all -j$(nproc) -s"
echo "benchmark, dataset, version, threshold, coarsening, aggregation_granularity, runID, time" >$FILE
for dataset in "${DATASETS[@]}"; do
  for version in $VERSIONS; do
    if [ -f $NAME.$version ]; then
      for r in $(seq 1 $RUNS); do
        echo $NAME, $dataset, $version, N/A, N/A, N/A, $r, $(./$NAME.$version $dataset -o 0) | tee -a $FILE
      done
    fi
  done
done

for ((threshold = 1; threshold <= THRESHOLD_LIMIT; threshold *= 2)); do
  docker exec -it klap bash -c "cd /klap/test/${BENCHMARK}/ && make THRESHOLD_T=${threshold} $NAME.tcdp ${NAME}.taw ${NAME}.tag ${NAME}.tab -j$(nproc) -B -s"
  for dataset in "${DATASETS[@]}"; do
    for version in $THRESHOLD_VERSIONS; do
      if [ -f $NAME.$version ]; then
        for r in $(seq 1 $RUNS); do
          echo $NAME, $dataset, $version, $threshold, N/A, N/A, $r, $(./$NAME.$version $dataset -o 0) | tee -a $FILE
        done
      fi
    done
  done
done

sed -i -e 's/tcdp/t/g' $NAME.csv
sed -i -e 's/taw/t-a_warp/g' $NAME.csv
sed -i -e 's/tab/t-a_block/g' $NAME.csv
sed -i -e 's/tag/t-a_grid/g' $NAME.csv

for ((coarse_factor = 1; coarse_factor <= COARSE_LIMIT; coarse_factor *= 2)); do
  docker exec -it klap bash -c "cd /klap/test/${BENCHMARK}/ && make COARSE_FACTOR=${coarse_factor} all -j$(nproc) -B -s"
  for dataset in "${DATASETS[@]}"; do
    for version in $COARSE_VERSIONS; do
      if [ -f $NAME.$version ]; then
        for r in $(seq 1 $RUNS); do
          echo $NAME, $dataset, $version, N/A, $coarse_factor, N/A, $r, $(./$NAME.$version $dataset -o 0) | tee -a $FILE
        done
      fi
    done
  done
done

sed -i -e 's/ccdp1/c/g' $NAME.csv
sed -i -e 's/caw1/c-a_warp/g' $NAME.csv
sed -i -e 's/cab1/c-a_block/g' $NAME.csv
sed -i -e 's/cag1/c-a_grid/g' $NAME.csv

for ((coarse_factor = 1; coarse_factor <= COARSE_LIMIT; coarse_factor *= 2)); do
  for ((threshold = 1; threshold <= THRESHOLD_LIMIT; threshold *= 2)); do
    docker exec -it klap bash -c "cd /klap/test/${BENCHMARK}/ && make COARSE_FACTOR=${coarse_factor} THRESHOLD_T=${threshold} all -j$(nproc) -B -s"
    for dataset in "${DATASETS[@]}"; do
      for version in $THRESHOLD_COARSE_VERSIONS; do
        if [ -f $NAME.$version ]; then
          for r in $(seq 1 $RUNS); do
            echo $NAME, $dataset, $version, $threshold, $coarse_factor, N/A, $r, $(./$NAME.$version $dataset -o 0) | tee -a $FILE
          done
        fi
      done
    done
  done
done

sed -i -e 's/ctcdp1/t-c/g' $NAME.csv
sed -i -e 's/ctaw1/t-c-a_warp/g' $NAME.csv
sed -i -e 's/ctab1/t-c-a_block/g' $NAME.csv
sed -i -e 's/ctag1/t-c-a_grid/g' $NAME.csv

for ((aggregation_gran = 32; aggregation_gran <= AGGREGATION_LIMIT; aggregation_gran += 32)); do
  for ((coarse_factor = 1; coarse_factor <= COARSE_LIMIT; coarse_factor *= 2)); do
    for ((threshold = 1; threshold <= THRESHOLD_LIMIT; threshold *= 2)); do
      docker exec -it klap bash -c "cd /klap/test/${BENCHMARK}/ && make COARSE_FACTOR=${coarse_factor} THRESHOLD_T=${threshold} GRANULARITY=${aggregation_gran} all -j$(nproc) -B -s"

      for dataset in "${DATASETS[@]}"; do
        for version in $DYNAMIC_AGG_VERSIONS_ALL; do
          if [ -f $NAME.$version ]; then
            for r in $(seq 1 $RUNS); do
              echo $NAME, $dataset, $version, $threshold, $coarse_factor, $aggregation_gran, $r, $(./$NAME.$version $dataset -o 0) | tee -a $FILE
            done
          fi
        done
      done
    done
  done
done

sed -i -e 's/ctdag1/t-c-a_multi/g' $NAME.csv

make clean
