/* Authors: Ketan Date, Vikram Sharma Mailthody, Izzat El Hajj */

#include <iostream>
#include <unistd.h>

#include "common.h"

int main(int argc, char* argv[]){

    // Parameters
    const char* graph    = "inputs/email-EuAll_adj.tsv";
    int numEdges         = 364481;
    bool printGraphInfo  = false;
    int warmup           = 1;
    int runs             = 3;
    int outputLevel      = 1;
    bool runBaseline     = true;
    bool runDP           = true;
    int dpThreshold      = 4096;
    int dpLimit          = 8192;
    int dpChildBlockSize = 1024;
    int opt;
    while((opt = getopt(argc, argv, "g:e:iw:r:o:bdt:l:c:h")) >= 0) {
        switch(opt) {
            case 'g': graph            = optarg;       break;
            case 'e': numEdges         = atoi(optarg); break;
            case 'i': printGraphInfo   = true;         break;
            case 'w': warmup           = atoi(optarg); break;
            case 'r': runs             = atoi(optarg); break;
            case 'o': outputLevel      = atoi(optarg); break;
            case 'b': runBaseline      = false;        break;
            case 'd': runDP            = false;        break;
            case 't': dpThreshold      = atoi(optarg); break;
            case 'l': dpLimit          = atoi(optarg); break;
            case 'c': dpChildBlockSize = atoi(optarg); break;
            default : std::cerr <<
                          "\nUsage:  ./tc [options]"
                          "\n"
                          "\nApplication options:"
                          "\n    -g <G>    graph (default=" << graph << ")"
                          "\n    -e <E>    # edges to process on one GPU (default=" << numEdges << ")"
                          "\n    -i        instead of running the benchmark, print information about the graph"
                          "\n"
                          "\nBenchmarking options:"
                          "\n    -w <W>    # of warmup runs (default=" << warmup << ")"
                          "\n    -r <R>    # of timed runs (default=" << runs << ")"
                          "\n    -o <O>    level of output outputLevel - 0: one CSV row, 1: moderate, 2: verbose (default=" << outputLevel << ")"
                          "\n    -b        do not run baseline (without dynamic parallelism) version"
                          "\n    -d        do not run dynamic parallelism version"
                          "\n"
                          "\nDynamic parallelism options:"
                          "\n    -t <T>    minimum threshold number of edges for performing a dynamic kernel launch (default=" << dpThreshold << ")"
                          "\n    -l <L>    maximum limit on the number of child threads per parent thread before coarsening (default=" << dpLimit << ")"
                          "\n    -c <C>    number of child threads per child block (default=" << dpChildBlockSize << ")"
                          "\n"
                          "\nHelp options:"
                          "\n    -h        help\n\n";
                      exit(0);
        }
    }

	CuTriangleCounter cutc;
	cutc.execute(graph, numEdges, printGraphInfo, warmup, runs, outputLevel, runBaseline, runDP, dpThreshold, dpLimit, dpChildBlockSize);

	return 0;

}





