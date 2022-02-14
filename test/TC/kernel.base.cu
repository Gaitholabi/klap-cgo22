/* Authors: Ketan Date, Vikram Sharma Mailthody, Izzat El Hajj */

#include "binary_search.h"

__global__ void kernel_triangleCounter_tc_cdp_child(long long int edge_id, unsigned long long int *cpu_tc, int *cpu_edgeids_src, int *cpu_edgeids_dest, long long int *cpu_rowptrs, long long int offset) {

    int u = cpu_edgeids_src[edge_id+offset];
    long long int u_edges_start = cpu_rowptrs[u];
    long long int u_edges_end = cpu_rowptrs[u + 1];
    long long int n_u_edges = u_edges_end - u_edges_start;

    int v = cpu_edgeids_dest[edge_id+offset];
    long long int v_edges_start = cpu_rowptrs[v];
    long long int v_edges_end = cpu_rowptrs[v + 1];
    long long int n_v_edges = v_edges_end - v_edges_start;

    // Process edges of the node with the larger degree in parallel
    unsigned int u_is_parallel = n_u_edges >= n_v_edges;
    long long int parallel_edges_start = u_is_parallel?u_edges_start:v_edges_start;
    long long int parallel_edges_end = u_is_parallel?u_edges_end:v_edges_end;
    long long int parallel_n_edges = parallel_edges_end - parallel_edges_start;

    // Process edges of the node with the smaller degree serially
    unsigned int u_is_serial = !u_is_parallel;
    long long int serial_edges_start = u_is_serial?u_edges_start:v_edges_start;
    long long int serial_edges_end = u_is_serial?u_edges_end:v_edges_end;
    // Coarsening loop of parallel edges
    unsigned long long count = 0;
    unsigned int idx = blockIdx.x*blockDim.x + threadIdx.x;
    if(idx < parallel_n_edges) {

        // Identify edge to search for
        long long int parallel_edge_idx = parallel_edges_start + idx;
        int search_val = cpu_edgeids_dest[parallel_edge_idx];
        count += binary_search(cpu_edgeids_dest, serial_edges_start, serial_edges_end - 1, search_val);
    }

    // Increment global counter
    if(count > 0) {
        atomicAdd(&(cpu_tc[edge_id + offset]), count);
    }

}

__global__ void kernel_triangleCounter_tc_cdp(unsigned long long int *cpu_tc, int *cpu_edgeids_src, int *cpu_edgeids_dest, long long int *cpu_rowptrs, long long int size, long long int offset, int dpThreshold, int dpLimit, int dpChildBlockSize) {

	long long int id = blockIdx.x*blockDim.x + threadIdx.x;

	if (id < size) {

		int u = cpu_edgeids_src[id+offset];
        long long int u_edges_start = cpu_rowptrs[u];
        long long int u_edges_end = cpu_rowptrs[u + 1];
		long long int n_u_edges = u_edges_end - u_edges_start;

        int v = cpu_edgeids_dest[id+offset];
        long long int v_edges_start = cpu_rowptrs[v];
        long long int v_edges_end = cpu_rowptrs[v + 1];
		long long int n_v_edges = v_edges_end - v_edges_start;

        unsigned int max_n_edges = (n_u_edges >= n_v_edges)?n_u_edges:n_v_edges;

        if(max_n_edges < dpThreshold) {

            long long int u_edge_idx = u_edges_start;
            int u_edge = cpu_edgeids_dest[u_edge_idx];

            long long int v_edge_idx = v_edges_start;
            int v_edge = cpu_edgeids_dest[v_edge_idx];

            long long int count = 0;
            while (u_edge_idx < u_edges_end && v_edge_idx < v_edges_end){
                if (u_edge == v_edge) {
                    ++count;
                    ++u_edge_idx;
                    ++v_edge_idx;
                    if ((u_edge_idx < u_edges_end && v_edge_idx < v_edges_end)) {
                        u_edge = cpu_edgeids_dest[u_edge_idx];
                        v_edge = cpu_edgeids_dest[v_edge_idx];
                    }

                }
                else if (u_edge < v_edge){
                    ++u_edge_idx;
                    if ((u_edge_idx < u_edges_end && v_edge_idx < v_edges_end)) {
                        u_edge = cpu_edgeids_dest[u_edge_idx];
                    }

                } else {
                    ++v_edge_idx;
                    if ((u_edge_idx < u_edges_end && v_edge_idx < v_edges_end)) {
                        v_edge = cpu_edgeids_dest[v_edge_idx];
                    }

                }
            }
            cpu_tc[id + offset] = count;

        } else {

            cpu_tc[id + offset] = 0;
            unsigned int min_n_edges = (n_u_edges < n_v_edges)?n_u_edges:n_v_edges;
            if(min_n_edges > 0) {
                unsigned int numChildThreads = max_n_edges;
                unsigned int numChildBlocks = (numChildThreads - 1)/dpChildBlockSize + 1;
                kernel_triangleCounter_tc_cdp_child<<<numChildBlocks, dpChildBlockSize>>>(id, cpu_tc, cpu_edgeids_src, cpu_edgeids_dest, cpu_rowptrs, offset);
            }

        }
	}
}

void launch_kernel(unsigned int blocks_per_grid, unsigned int threads_per_block, unsigned long long int *cpu_tc, int *cpu_edgeids_src, int *cpu_edgeids_dest, long long int *cpu_rowptrs, long long int size, long long int offset, int dpThreshold, int dpLimit, int dpChildBlockSize) {
    kernel_triangleCounter_tc_cdp <<<blocks_per_grid, threads_per_block>>>(cpu_tc, cpu_edgeids_src, cpu_edgeids_dest, cpu_rowptrs, size, offset, dpThreshold, dpLimit, dpChildBlockSize);
}

