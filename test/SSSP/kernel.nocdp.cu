
#include "common.h"

__global__ void drelax(foru *dist, Graph graph, bool *changed) {
    unsigned idx = blockIdx.x * blockDim.x + threadIdx.x;

    if(idx < graph.nnodes) {
        unsigned neighborsize = graph.getOutDegree(idx);
        if (neighborsize >= 1) {
            for (unsigned int id = 0; id < neighborsize; ++id) {
                unsigned dst = graph.nnodes;
                foru olddist = processedge(dist, graph, idx, id, dst);
                if (olddist) {
                    *changed = true;
                }
            }
        }
    }
}

void launch_kernel(unsigned int nb, unsigned int nt, foru *dist, Graph graph, bool *changed) {
    drelax <<<nb, nt>>> (dist, graph, changed);
}

