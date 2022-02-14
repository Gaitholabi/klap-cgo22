
#include "common.h"

__global__ void drelax_child(foru *dist, Graph graph, bool *changed, unsigned neighborsize, unsigned work) {
    unsigned id = blockIdx.x * blockDim.x + threadIdx.x;

    if (id < neighborsize) {
        unsigned dst = graph.nnodes;
        foru olddist = processedge(dist, graph, work, id, dst);
        if (olddist) {
            *changed = true;
        }
    }
}

__global__ void drelax(foru *dist, Graph graph, bool *changed) {
    unsigned idx = blockIdx.x * blockDim.x + threadIdx.x;
    if(idx < graph.nnodes) {
        unsigned neighborsize = graph.getOutDegree(idx);
        if (neighborsize >= 1) {
            unsigned blocks = (neighborsize + BLOCK_DIM - 1) / BLOCK_DIM;
            drelax_child<<<blocks, BLOCK_DIM>>>(dist, graph, changed, neighborsize, idx);
        }
    }
}

void launch_kernel(unsigned int nb, unsigned int nt, foru *dist, Graph graph, bool *changed) {
    drelax <<<nb, nt>>> (dist, graph, changed);
}

