
#include "common.h"

__global__ void dfindelemin2_nocdp(unsigned *mstwt, Graph graph, ComponentSpace cs, foru *eleminwts, foru *minwtcomponent, unsigned *partners, unsigned *phore, bool *processinnextiteration, unsigned *goaheadnodeofcomponent, unsigned inpid) {
    unsigned id = blockIdx.x * blockDim.x + threadIdx.x;
    if (id < graph.nnodes) {
        unsigned src = id;
        unsigned srcboss = cs.find(src);
        if(eleminwts[id] == minwtcomponent[srcboss] && srcboss != partners[id] && partners[id] != graph.nnodes)
        {
            unsigned degree = graph.getOutDegree(src);
            for(unsigned ii = 0; ii < degree; ++ii) {
                foru wt = graph.getWeight(src, ii); //
                if (wt == eleminwts[id]) {
                    unsigned dst = graph.getDestination(src, ii); //
                    unsigned tempdstboss = cs.find(dst);
                    if (tempdstboss == partners[id]) {	// cross-component edge.
                        //atomicMin(&goaheadnodeofcomponent[srcboss], id);
                        if(atomicCAS(&goaheadnodeofcomponent[srcboss], graph.nnodes, id) == graph.nnodes)
                        {
                            //printf("%d: adding %d\n", id, eleminwts[id]);
                            //atomicAdd(wt2, eleminwts[id]);
                        }
                    }
                }
            }
        }
    }
}

__global__ void verify_min_elem_nocdp(unsigned *mstwt, Graph graph, ComponentSpace cs, foru *eleminwts, foru *minwtcomponent, unsigned *partners, unsigned *phore, bool *processinnextiteration, unsigned *goaheadnodeofcomponent, unsigned inpid) {
    unsigned id = blockIdx.x * blockDim.x + threadIdx.x;
    if (inpid < graph.nnodes) id = inpid;


    if (id < graph.nnodes) {

        if(cs.isBoss(id)) {

            if(goaheadnodeofcomponent[id] != graph.nnodes) {
                unsigned minwt_node = goaheadnodeofcomponent[id];
                unsigned degree = graph.getOutDegree(minwt_node);
                foru minwt = minwtcomponent[id];

                if(minwt != MYINFINITY) {
                    for(unsigned ii = 0; ii < degree; ++ii) {
                        foru wt = graph.getWeight(minwt_node, ii);
                        //printf("%d: looking at %d edge %d wt %d (%d)\n", id, minwt_node, ii, wt, minwt);

                        if (wt == minwt) {
                            //minwt_found = true;
                            unsigned dst = graph.getDestination(minwt_node, ii);
                            unsigned tempdstboss = cs.find(dst);
                            if(tempdstboss == partners[minwt_node] && tempdstboss != id)
                            {
                                processinnextiteration[minwt_node] = true;
                                //printf("%d okay!\n", id);
                            }
                        }
                    }
                }
            }
        }
    }

}

void launch_find_kernel(unsigned int nb, unsigned int nt, unsigned *mstwt, Graph graph, ComponentSpace cs, foru *eleminwts, foru *minwtcomponent, unsigned *partners, unsigned *phore, bool *processinnextiteration, unsigned *goaheadnodeofcomponent, unsigned inpid) {
    dfindelemin2_nocdp<<<nb, nt>>>(mstwt, graph, cs, eleminwts, minwtcomponent, partners, phore, processinnextiteration, goaheadnodeofcomponent, inpid);
}

void launch_verify_kernel(unsigned int nb, unsigned int nt, unsigned *mstwt, Graph graph, ComponentSpace cs, foru *eleminwts, foru *minwtcomponent, unsigned *partners, unsigned *phore, bool *processinnextiteration, unsigned *goaheadnodeofcomponent, unsigned inpid) {
    verify_min_elem_nocdp<<<nb, nt>>>(mstwt, graph, cs, eleminwts, minwtcomponent, partners, phore, processinnextiteration, goaheadnodeofcomponent, inpid);
}

