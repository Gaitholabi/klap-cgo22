# KLAP-CGO Artifact Submission

## Hardware Requirements

* CUDA Capable device

## Software Requirements

* [Docker Engine](https://docs.docker.com/engine/install/)
* Relevant drivers for your CUDA Capable device

## Artifact

### The artifact provides three main components

* Datasets used to conduct the experiments
* Source code for benchmarks (obtained from third parties, sourced are provided inside the directory of each benchmark respectively)
* Docker image


## Usage

### Installation

In order to unpack the datasets and load the docker image, you can use the convenience script:

```shell
bash import.sh
```

### Running

In order to run a container in the background, you can use the convenience script:

```shell
bash run.sh
```

### Running the experiments

#### Provided workflows

We provide two workflows.

##### Exhaustive Search
The first workflow is a slightly tweaked version of the one we've used to obtain the results (tweaks are majorly just adapting to docker). The exhaustive search workflow tunes and repeatedly recompiles the binaries and runs them to explore the design space. The tuned parameters includes `threshold`, `coarsening factor`, `aggregation type`, `aggregation granularity`. 

This workflow is run for every benchmark separately, and can be invoked by running `sweep.sh` for each benchmark from its directory respectively:
```shell
bash sweep.sh
```

**Note**: this flow can take many hours to finish (for each benchmark) running all iterations.

##### Best combination

The second workflow is essentially the result of running the exhaustive search, parsing the data, and picking the best tuned parameters.
The values of the tuned parameters are **manually** picked and added to this script, which only runs one variation. 

This workflow is also per benchmark, and can be invoked by running:

```shell
bash best_combination.sh
```

## Datasets

Given that the benchmarks uses a different format of the same graphs, we provide the datasets in a combined folder. The following maps  each format to the relevant benchmark.

* `*.graph` is used by BFS
* `*.gr` is used by MST, SSSP
* `*.tsv` is used by TC
* `*.cnf` is used by SP
* BT does not require a dataset. Please check the `--help` option for more information.

Sources and references for the datasets are respectively provided in the dataset.


#### Customized workflows

Aside from running the experiments using our provided scripts, you can manually compile and invoke the binaries for each benchmark.
To compile all the binaries for a certain benchmark so you can run them on the host:

```shell
benchmark=BFS
docker exec -it klap bash -c "cd /klap/test/${benchmark} && make all"
```

The list of generated binaries for each benchmark as a result of `make all`, the below list is a non exclusive convention based:

- NOCDP: manual version that doesn't apply cuda dynamic parallelism
- CDP: manual version that applies cuda dynamic parallelism
- AW: aggregation with warp granularity
- AB: aggregation with block granularity
- AG: aggregation with grid granularity
- TCDP: CDP + T
- CCDP: CDP + C
- CTCDP: CDP + T + C
- CTAW: CDP  + T + C + AW
- CTAB: CDP  + T + C + AB
- CTAG: CDP  + T + C  + AG
- ...

After benchmarks compiling the binaries, as an example, you can lookup the run options for each by running:

```shell
./bfs.cdp --help
```

## Source Code Compilation and Usage

### Software requirements

The software is compiled and verified to work with the following versions of the dependencies:
* LLVM version 7.0.0
* GCC version 6.4.0
* CUDA 9.1

The source code for the transformations is available under [src/](src/). Please check the [compilation steps](src/README.md)
