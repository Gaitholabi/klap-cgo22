/* Authors: Ketan Date, Vikram Sharma Mailthody */

#include <iostream>
#include <fstream>
#include <sstream>
#include <map>
#include <set>
#include <cuda.h>
#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <cassert>
#include <algorithm>

#include "utilities.h"

class CuTriangleCounter {

        long long int edge_split[NUMDEV + 1]; 
        long long int *d_edgeids_dev[NUMDEV];
        long long int *d_rowptrs_dev[NUMDEV];

        int nodecount;
        long long int edgecount, working_edgecount;

        std::vector<long long int> edge_vec, row_ptrs_vec;
        std::vector<int> edge_vec_src, edge_vec_dest;

        struct AdjList{
            long long int *edgeids;
            long long int *rowptrs;
            int *edgeids_src;
            int *edgeids_dest;
        } graph, graph_dev[NUMDEV];

        long long int *working_edgelist_dev[NUMDEV], *working_edgelist;

        unsigned long long int *d_tc;


    public:

        void execute(const char* filename, int numEdges, bool printGraphInfo, int warmup, int runs, int outputLevel, bool runBaseline, bool runDP, int dpThreshold, int dpLimit, int dpChildBlockSize);

    private:

        long long int countTriangles(int warmup, int runs, int outputLevel, bool runBaseline, bool runDP, int dpThreshold, int dpLimit, int dpChildBlockSize);
        void allocArrays(void);
        void freeArrays(void);

};

__global__ void kernel_triangleCounter_tc(unsigned long long int *cpu_tc, int *cpu_edgeids_src, int *cpu_edgeids_dest, long long int *cpu_rowptrs, long long int size, long long int offset);

void launch_kernel(unsigned int blocks_per_grid, unsigned int threads_per_block, unsigned long long int *cpu_tc, int *cpu_edgeids_src, int *cpu_edgeids_dest, long long int *cpu_rowptrs, long long int size, long long int offset, int dpThreshold, int dpLimit, int dpChildBlockSize);

