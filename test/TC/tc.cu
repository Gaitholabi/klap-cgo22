
/* Authors: Ketan Date, Vikram Sharma Mailthody, Izzat El Hajj */

#include <thrust/sort.h>
#include <thrust/scan.h>
#include <thrust/host_vector.h>
#include <thrust/device_ptr.h>

#include "common.h"
#include "utilities.h"

void CuTriangleCounter::execute(const char* filename, int numEdges, bool printGraphInfo, int warmup, int runs, int outputLevel, bool runBaseline, bool runDP, int dpThreshold, int dpLimit, int dpChildBlockSize) {

    // Read graph
    readGraph_DARPA_CSR(filename, edge_vec_src, edge_vec_dest, row_ptrs_vec, edgecount, nodecount);
    working_edgecount = (numEdges < edgecount)?numEdges:edgecount;
    if(printGraphInfo) {
        // Basic info
        printf("\n");
        printf("file = %s\n", filename);
        printf("# nodes = %d\n", nodecount);
        printf("# edges = %lld\n", edgecount);
        printf("# edges processed = %lld\n", working_edgecount);
        // Node degree info
        int maxDegree = 0;
        int histogramNodesByDegree[10] = {0}; // < 32, 32-64, 64-128, 128-256, 256-512, 512-1024, 1024-2048, 2048-4096, 4096-8192, > 8192
        for(unsigned int n = 0; n < nodecount; ++n) {
            unsigned int n_edges = row_ptrs_vec[n + 1] - row_ptrs_vec[n];
            maxDegree = (n_edges > maxDegree)?n_edges:maxDegree;
            if(n_edges < 32)        ++histogramNodesByDegree[0];
            else if(n_edges < 64)   ++histogramNodesByDegree[1];
            else if(n_edges < 128)  ++histogramNodesByDegree[2];
            else if(n_edges < 256)  ++histogramNodesByDegree[3];
            else if(n_edges < 512)  ++histogramNodesByDegree[4];
            else if(n_edges < 1024) ++histogramNodesByDegree[5];
            else if(n_edges < 2048) ++histogramNodesByDegree[6];
            else if(n_edges < 4096) ++histogramNodesByDegree[7];
            else if(n_edges < 8192) ++histogramNodesByDegree[8];
            else                    ++histogramNodesByDegree[9];
        }
        printf("\n");
        printf("average degree = %lld\n", edgecount/nodecount);
        printf("max degree = %d\n", maxDegree);
        printf("histogram of nodes by degree:\t%d (< 32),\t%d (32-64),\t%d (64-128),\t%d (128-256),\t%d (256-512),\t%d (512-1024),\t%d (1024-2048),\t%d (2048-4096),\t%d (4096-8192),\t%d (> 8192)\n", histogramNodesByDegree[0], histogramNodesByDegree[1], histogramNodesByDegree[2], histogramNodesByDegree[3], histogramNodesByDegree[4], histogramNodesByDegree[5], histogramNodesByDegree[6], histogramNodesByDegree[7], histogramNodesByDegree[8], histogramNodesByDegree[9]);
        // Edge adjacency info (number of edges sharing a node with the edge)
        int sumAdjacency = 0;
        int maxAdjacency = 0;
        int histogramEdgesByAdjacency[10] = {0}; // < 32, 32-64, 64-128, 128-256, 256-512, 512-1024, 1024-2048, 2048-4096, 4096-8192, > 8192
        for(unsigned int e = 0; e < edgecount; ++e) {
            unsigned int head = edge_vec_src[e];
            unsigned int tail = edge_vec_dest[e];
            unsigned int n_edges_head = row_ptrs_vec[head + 1] - row_ptrs_vec[head];
            unsigned int n_edges_tail = row_ptrs_vec[tail + 1] - row_ptrs_vec[tail];
            unsigned int adjacency = n_edges_head + n_edges_tail;
            sumAdjacency += adjacency;
            maxAdjacency = (adjacency > maxAdjacency)?adjacency:maxAdjacency;
            if(adjacency < 32)        ++histogramEdgesByAdjacency[0];
            else if(adjacency < 64)   ++histogramEdgesByAdjacency[1];
            else if(adjacency < 128)  ++histogramEdgesByAdjacency[2];
            else if(adjacency < 256)  ++histogramEdgesByAdjacency[3];
            else if(adjacency < 512)  ++histogramEdgesByAdjacency[4];
            else if(adjacency < 1024) ++histogramEdgesByAdjacency[5];
            else if(adjacency < 2048) ++histogramEdgesByAdjacency[6];
            else if(adjacency < 4096) ++histogramEdgesByAdjacency[7];
            else if(adjacency < 8192) ++histogramEdgesByAdjacency[8];
            else                      ++histogramEdgesByAdjacency[9];
        }
        printf("\n");
        printf("average adjacency = %lld\n", sumAdjacency/edgecount);
        printf("max adjacency = %d\n", maxAdjacency);
        printf("histogram of edges by adjacency:\t%d (< 32),\t%d (32-64),\t%d (64-128),\t%d (128-256),\t%d (256-512),\t%d (512-1024),\t%d (1024-2048),\t%d (2048-4096),\t%d (4096-8192),\t%d (> 8192)\n", histogramEdgesByAdjacency[0], histogramEdgesByAdjacency[1], histogramEdgesByAdjacency[2], histogramEdgesByAdjacency[3], histogramEdgesByAdjacency[4], histogramEdgesByAdjacency[5], histogramEdgesByAdjacency[6], histogramEdgesByAdjacency[7], histogramEdgesByAdjacency[8], histogramEdgesByAdjacency[9]);
        // Edge adjacency info with max node only (degree of the larger node adjacent to the edge)
        int sumAdjacencyMax = 0;
        int maxAdjacencyMax = 0;
        int histogramEdgesByAdjacencyMax[10] = {0}; // < 32, 32-64, 64-128, 128-256, 256-512, 512-1024, 1024-2048, 2048-4096, 4096-8192, > 8192
        for(unsigned int e = 0; e < edgecount; ++e) {
            unsigned int head = edge_vec_src[e];
            unsigned int tail = edge_vec_dest[e];
            unsigned int n_edges_head = row_ptrs_vec[head + 1] - row_ptrs_vec[head];
            unsigned int n_edges_tail = row_ptrs_vec[tail + 1] - row_ptrs_vec[tail];
            unsigned int adjacencyMax = (n_edges_head > n_edges_tail)?n_edges_head:n_edges_tail;
            sumAdjacencyMax += adjacencyMax;
            maxAdjacencyMax = (adjacencyMax > maxAdjacencyMax)?adjacencyMax:maxAdjacencyMax;
            if(adjacencyMax < 32)        ++histogramEdgesByAdjacencyMax[0];
            else if(adjacencyMax < 64)   ++histogramEdgesByAdjacencyMax[1];
            else if(adjacencyMax < 128)  ++histogramEdgesByAdjacencyMax[2];
            else if(adjacencyMax < 256)  ++histogramEdgesByAdjacencyMax[3];
            else if(adjacencyMax < 512)  ++histogramEdgesByAdjacencyMax[4];
            else if(adjacencyMax < 1024) ++histogramEdgesByAdjacencyMax[5];
            else if(adjacencyMax < 2048) ++histogramEdgesByAdjacencyMax[6];
            else if(adjacencyMax < 4096) ++histogramEdgesByAdjacencyMax[7];
            else if(adjacencyMax < 8192) ++histogramEdgesByAdjacencyMax[8];
            else                         ++histogramEdgesByAdjacencyMax[9];
        }
        printf("\n");
        printf("average adjacency with max node only = %lld\n", sumAdjacencyMax/edgecount);
        printf("max adjacency with max node only = %d\n", maxAdjacency);
        printf("histogram of edges by adjacency with max node only:\t%d (< 32),\t%d (32-64),\t%d (64-128),\t%d (128-256),\t%d (256-512),\t%d (512-1024),\t%d (1024-2048),\t%d (2048-4096),\t%d (4096-8192),\t%d (> 8192)\n", histogramEdgesByAdjacencyMax[0], histogramEdgesByAdjacencyMax[1], histogramEdgesByAdjacencyMax[2], histogramEdgesByAdjacencyMax[3], histogramEdgesByAdjacencyMax[4], histogramEdgesByAdjacencyMax[5], histogramEdgesByAdjacencyMax[6], histogramEdgesByAdjacencyMax[7], histogramEdgesByAdjacencyMax[8], histogramEdgesByAdjacencyMax[9]);
         printf("\n");
        return;
    }

    // Initialize GPU
    cudaDeviceSynchronize();
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    // Allocation
    cudaEventRecord(start, NULL);
    allocArrays();
    cudaEventRecord(stop, NULL);
    cudaEventSynchronize(stop);
    float allocTime = 0.0f;
    cudaEventElapsedTime(&allocTime, start, stop);
    if(outputLevel >= 2) std::cout << "allocation time = " << allocTime << std::endl;

    // Kernel
    countTriangles(warmup, runs, outputLevel, runBaseline, runDP, dpThreshold, dpLimit, dpChildBlockSize);

    // Free arrays
    cudaEventRecord(start, NULL);
    freeArrays();
    cudaEventRecord(stop, NULL);
    cudaEventSynchronize(stop);
    float freeTime = 0.0f;
    cudaEventElapsedTime(&freeTime, start, stop);
    if(outputLevel >= 2) std::cout << "free time = " << freeTime << std::endl;

}

long long int CuTriangleCounter::countTriangles(int warmup, int runs, int outputLevel, bool runBaseline, bool runDP, int dpThreshold, int dpLimit, int dpChildBlockSize) {

    int devid = 0;
    checkCuda(cudaSetDevice(devid));
    cudaDeviceSetLimit(cudaLimitDevRuntimePendingLaunchCount, working_edgecount);

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    // Configure triangle count kernel
    long long int gpu_edgecount = working_edgecount;
    unsigned int threads_per_block = BLOCKDIMX*BLOCKDIMY;
    unsigned int blocks_per_grid = (gpu_edgecount - 1)/threads_per_block + 1;

    // Run kernel multiple times
    long long int tc;
    float totalKernelTime = 0;
    float totalKernelTimeCDP = 0;
    for(int run = -warmup; run < runs; run++) {

        if(outputLevel >= 1) {
            if(run < 0) {
                std::cout << "Warmup:\t";
            } else {
                std::cout << "Run " << run << ":\t";
            }
        }

        thrust::device_ptr<unsigned long long int> ptr(d_tc);
        if(runBaseline) {

            // Launch triangle count kernel
            cudaEventRecord(start, NULL);
            kernel_triangleCounter_tc <<<blocks_per_grid, threads_per_block>>>(d_tc, graph.edgeids_src, graph.edgeids_dest, graph.rowptrs, gpu_edgecount, 0);
            cudaEventRecord(stop, NULL);
            cudaEventSynchronize(stop);
            float kernelTime = 0.0f;
            cudaEventElapsedTime(&kernelTime, start, stop);
            if(outputLevel >= 1) std::cout << "kernel time = " << kernelTime;
            if (run >= 0) totalKernelTime += kernelTime;

            // Find total triangle count across all edges
            cudaEventRecord(start, NULL);
            tc = thrust::reduce(ptr, ptr + gpu_edgecount);
            cudaEventRecord(stop, NULL);
            cudaEventSynchronize(stop);
            float reduceTime = 0.0f;
            cudaEventElapsedTime(&reduceTime, start, stop);
            if(outputLevel >= 1) std::cout << ", reduce time = " << reduceTime;

            // Result
            if(outputLevel >= 1) std::cout << ", triangle count = " << tc;

        }

        if(runBaseline && runDP && outputLevel >= 1) std::cout << " , ";

        if(runDP) {

            // Launch triangle count kernel (CDP)
            cudaEventRecord(start, NULL);
            launch_kernel(blocks_per_grid, threads_per_block, d_tc, graph.edgeids_src, graph.edgeids_dest, graph.rowptrs, gpu_edgecount, 0, dpThreshold, dpLimit, dpChildBlockSize);
            cudaEventRecord(stop, NULL);
            cudaEventSynchronize(stop);
            float kernelTimeCDP = 0.0f;
            cudaEventElapsedTime(&kernelTimeCDP, start, stop);
            if(outputLevel >= 1) std::cout << "kernel time (CDP) = " << kernelTimeCDP;
            if (run >= 0) totalKernelTimeCDP += kernelTimeCDP;

            // Find total triangle count across all edges (CDP)
            cudaEventRecord(start, NULL);
            tc = thrust::reduce(ptr, ptr + gpu_edgecount);
            cudaEventRecord(stop, NULL);
            cudaEventSynchronize(stop);
            float reduceTimeCDP = 0.0f;
            cudaEventElapsedTime(&reduceTimeCDP, start, stop);
            if(outputLevel >= 1) std::cout << ", reduce time (CDP) = " << reduceTimeCDP;

            // Result
            if(outputLevel >= 1) std::cout << ", triangle count (CDP) = " << tc;

        }

        if(outputLevel >= 1) std::cout << std::endl;

    }

    // Timing
    if(outputLevel >= 1) {
        if(runBaseline) std::cout<< "Average kernel time = " << totalKernelTime/runs << " ms\n";
        if(runDP) std::cout<< "Average kernel time (CDP) = " << totalKernelTimeCDP/runs << " ms\n";
    } else {
        if(runDP) {
            std::cout<< totalKernelTimeCDP/runs;
        } else if(runBaseline) {
            std::cout<< totalKernelTime/runs;
        }
    }

    return tc;

}

void CuTriangleCounter::allocArrays(void){

    int devid = 0;
    checkCuda(cudaSetDevice(devid));

    cudaStream_t streams[3];
    for(int i = 0; i < 3; i++)
        cudaStreamCreate(&streams[i]);

    checkCuda(cudaMalloc((void**)&d_tc, edgecount * sizeof(unsigned long long int)));
    checkCuda(cudaMalloc((void**)&graph.edgeids_src , edgecount * sizeof(int)));
    checkCuda(cudaMalloc((void**)&graph.edgeids_dest, edgecount * sizeof(int)));
    checkCuda(cudaMalloc((void**)&graph.rowptrs, (nodecount + 1) * sizeof(long long int)));

    checkCuda(cudaMemcpyAsync(graph.edgeids_src , edge_vec_src.data() , edgecount * sizeof(int),  cudaMemcpyHostToDevice, streams[0]));
    checkCuda(cudaMemcpyAsync(graph.edgeids_dest, edge_vec_dest.data(), edgecount * sizeof(int),  cudaMemcpyHostToDevice, streams[1]));
    checkCuda(cudaMemcpyAsync(graph.rowptrs, row_ptrs_vec.data(), (nodecount + 1) * sizeof(long long int), cudaMemcpyHostToDevice, streams[2]));

    for(int i = 0; i < 3; i++){
        cudaStreamSynchronize(streams[i]);
        cudaStreamDestroy(streams[i]);
    }

    row_ptrs_vec.clear();
    edge_vec_src.clear();
    edge_vec_dest.clear();

}

void CuTriangleCounter::freeArrays(void){

    int devid = 0;
    checkCuda(cudaSetDevice(devid));

    checkCuda(cudaFree(graph.edgeids_src));
    checkCuda(cudaFree(graph.edgeids_dest));
    checkCuda(cudaFree(graph.rowptrs));
    checkCuda(cudaFree(d_tc));

}

__global__ void kernel_triangleCounter_tc(unsigned long long int *cpu_tc, int *cpu_edgeids_src, int *cpu_edgeids_dest, long long int *cpu_rowptrs, long long int size, long long int offset){

    long long int id = blockIdx.x*blockDim.x + threadIdx.x;

    if (id < size) {

        long long int count = 0;

        int u, v;
        //long long int e = working_edgelist[id + offset];
        //decodeEdge(u, v, e);
        u = cpu_edgeids_src[id+offset];
        v = cpu_edgeids_dest[id+offset];

        long long int u_ptr = cpu_rowptrs[u];
        long long int u_end = cpu_rowptrs[u + 1];

        long long int v_ptr = cpu_rowptrs[v];
        long long int v_end = cpu_rowptrs[v + 1];
        int v_u, v_v;
        v_u = cpu_edgeids_dest[u_ptr];
        v_v = cpu_edgeids_dest[v_ptr];

        while (u_ptr < u_end && v_ptr < v_end){

            //long long int e_u = cpu_edgeids[u_ptr];
            //long long int e_v = cpu_edgeids[v_ptr];

            //int u_u, v_u, u_v, v_v;
            //u_u = cpu_edgeids[u_ptr+1];
            //u_v = cpu_edgeids[v_ptr+1];

            //decodeEdge(u_u, v_u, e_u);
            //decodeEdge(u_v, v_v, e_v);

            if (v_u == v_v) {
                ++count;
                v_u = cpu_edgeids_dest[++u_ptr];
                v_v = cpu_edgeids_dest[++v_ptr];
            }
            else if (v_u < v_v){
                v_u = cpu_edgeids_dest[++u_ptr];
                //++u_ptr;
            }
            else {
                v_v = cpu_edgeids_dest[++v_ptr];
                //++v_ptr;
            }
        }
        cpu_tc[id + offset] = count;
    }
}

