#!/bin/bash

NAME=tc
DATASETS=( "-g inputs/loc-gowalla_edges_adj.tsv" "-g inputs/email-EuAll_adj.tsv")

VERSIONS='base aw ab ag'
COARSE_VERSIONS='ccdp1 caw1 cab1 cag1 ccdp2 caw2 cab2 cag2 ccdp3 caw3 cab3 cag3'
RUNS=5
FILE=$NAME.csv
COARSE_LIMIT=2048
THRESHOLD_LIMIT=16384

make all -j$(nproc)
echo "benchmark, dataset, version, threshold, coarsening, runID, time" > $FILE
for dataset in "${DATASETS[@]}"; do
  for r in `seq 1 $RUNS`; do
      echo $NAME, $dataset, nocdp, N/A, N/A, $r, `./$NAME.base -o 0 -d $dataset` | tee -a $FILE
  done
done

for dataset in "${DATASETS[@]}"; do
  for version in $VERSIONS; do
      if [ -f $NAME.$version ]; then
          for r in `seq 1 $RUNS`; do
              echo $NAME, $dataset, $version, N/A, N/A, $r, `./$NAME.$version -o 0 -b -t 1 $dataset` | tee -a $FILE
          done
      fi
  done
done

for (( threshold=1; threshold<=THRESHOLD_LIMIT; threshold*=2 )); do
  for dataset in "${DATASETS[@]}"; do
    for version in $VERSIONS; do
        if [ -f $NAME.$version ]; then
            for r in `seq 1 $RUNS`; do
                echo $NAME, $dataset, t$version$threshold, $threshold, N/A, $r, `./$NAME.$version -o 0 -b -t $threshold $dataset` | tee -a $FILE
            done
        fi
    done
  done
done

for (( coarse_factor=1; coarse_factor<=COARSE_LIMIT; coarse_factor*=2)); do
  make COARSE_FACTOR=${coarse_factor} all -j$(nproc) -B -s
  for dataset in "${DATASETS[@]}"; do
    for version in $COARSE_VERSIONS; do
        if [ -f $NAME.$version ]; then
            for r in `seq 1 $RUNS`; do
                echo $NAME, $dataset, $version, N/A, $coarse_factor, $r, `./$NAME.$version -o 0 -b -t 1 $dataset` | tee -a $FILE
            done
        fi
    done
  done
done

for (( coarse_factor=1; coarse_factor<=COARSE_LIMIT; coarse_factor*=2)); do
  make COARSE_FACTOR=${coarse_factor} all -j$(nproc) -B -s
  for (( threshold=1; threshold<=THRESHOLD_LIMIT; threshold*=2 )); do
    for dataset in "${DATASETS[@]}"; do
      for version in $COARSE_VERSIONS; do
          if [ -f $NAME.$version ]; then
              for r in `seq 1 $RUNS`; do
                  echo $NAME, $dataset, t$version, $threshold, $coarse_factor $r, `./$NAME.$version -o 0 -b -t $threshold $dataset` | tee -a $FILE
              done
          fi
      done
    done
  done
done