
#include "common.h"

__global__ void decimate (GPUCSRGraph clauses, GPUCSRGraph vars, Edge ed, int *g_bias_list_vars,
        const int * bias_list_len, int fixperstep)
{
    int id = threadIdx.x + blockIdx.x * blockDim.x;

    int l = *bias_list_len - fixperstep + id;
    if(l < *bias_list_len) {
        int v = g_bias_list_vars[l];
        vars.sat[v] = true;
        int edoff = vars.row_offsets[v];
        int cllen = vars.degree(v);
        for(int edndx = 0; edndx < cllen; ++edndx) {
            int edge = vars.columns[edoff + edndx];
            int cl = ed.src[edge];

            if(!clauses.sat[cl])
                if(ed.bar[edge] != vars.value[v])
                    clauses.sat[cl] = true;
        }
    }
}

void launch_kernel(unsigned int nb, unsigned int nt, GPUCSRGraph clauses, GPUCSRGraph vars, Edge ed, int *g_bias_list_vars,const int * bias_list_len, int fixperstep) {
    decimate<<<(fixperstep - 1)/nt + 1, nt>>>(clauses, vars, ed, g_bias_list_vars, bias_list_len, fixperstep);
}

