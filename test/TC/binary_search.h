
#ifndef _TC_BINARY_SEARCH_H_
#define _TC_BINARY_SEARCH_H_

__device__ __inline__ int binary_search(int* array, int left, int right, int search_val) {
    while(left <= right) {
        int mid = (left + right)/2;
        int val = array[mid];
        if(val < search_val) {
            left = mid + 1;
        } else if(val > search_val) {
            right = mid - 1;
        } else { // val == search_val
            return 1;
        }
    }
    return 0;
}

#endif

