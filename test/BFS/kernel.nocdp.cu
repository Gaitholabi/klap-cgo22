
#include "common.h"

__global__ void BFS_nocdp(
        unsigned int *levels,
        unsigned int *edgeArray,
        unsigned int *edgeArrayAux,
        unsigned int numVertices,
        int curr,
        int *flag)
{
    int gid = blockDim.x*blockIdx.x + threadIdx.x;
    if(gid < numVertices){
        if(levels[gid] == curr){
            unsigned int nbr_off = edgeArray[gid];
            unsigned int num_nbr = edgeArray[gid + 1] - nbr_off;
            for(unsigned int nid = 0; nid < num_nbr; ++nid) {
                int v = edgeArrayAux[nid + nbr_off];
                if(levels[v] == UINT_MAX) {
                    levels[v] = curr + 1;
                    *flag = 1;
                }
            }
        }
    }
}

void launch_kernel(unsigned int *d_costArray, unsigned int *d_edgeArray, unsigned int *d_edgeArrayAux, unsigned int numVerts, int iters, int* d_flag) {
    unsigned int numBlocks = (numVerts - 1)/PARENT_BLOCK_SIZE + 1;
    BFS_nocdp<<<numBlocks,PARENT_BLOCK_SIZE>>>
        (d_costArray, d_edgeArray, d_edgeArrayAux, numVerts, iters, d_flag);
}

