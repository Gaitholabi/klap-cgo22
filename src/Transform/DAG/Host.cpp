/*
 *  Copyright (c) 2018 IMPACT Research Group, University of Illinois.
 *  All rights reserved.
 *
 *  This file is covered by the LICENSE.txt license file in the root directory.
 *
 */

#include "clang/AST/AST.h"
#include "clang/Rewrite/Core/Rewriter.h"
#include "llvm/Support/raw_ostream.h"

#include <sstream>
#include <string>

#include "Host.h"
#include "Analysis/KernelCallFinder.h"
#include "Driver/CompilerOptions.h"
#include "Utils/Utils.h"

using namespace clang;

HostDAGTransform::HostDAGTransform(Rewriter& rewriter, Analyzer& analyzer)
    : rewriter_(rewriter), analyzer_(analyzer) {}

bool HostDAGTransform::VisitStmt(Stmt *s) {

    if(CUDAKernelCallExpr* kernelCall = dyn_cast<CUDAKernelCallExpr>(s)) {
        if(analyzer_.isCallFromHostCandidate(kernelCall)) {

            /*
             * Transform the call to the original kernel:
             *
             *     kernel_name <<< gDim, bDim, smem >>> (p1, p2);
             *
             * into a call to the transformed kernel:
             *
             *      static __MemPool __memPool(memPoolSize_);
             *      __GridMemPool __memPoolHost(__memPool);
             *      __GridMemPool __memPoolDevice = __memPoolHost;
             *
             *      unsigned int __gDim = gDim;
             *      unsigned int __bDim = bDim;
             *      unsigned int __granularity = __GRANULARITY > __gDim ? __gDim : __GRANULARITY;
             *      unsigned int __totalNumOfBuckets = (__gDim + __granularity - 1) / __granularity;
             *      union scan_counter *_sc_ = __memPoolHost.grid_allocate<union scan_counter>(__totalNumOfBuckets);
             *      unsigned int *aggregationGranularityCounterBucket = __memPoolHost.grid_allocate<unsigned int>(__totalNumOfBuckets);
             *      cudaMemset(_sc_, 0, (sizeof(union scan_counter) + sizeof(unsigned int)) * __totalNumOfBuckets);
             *      // The kernel is called
             *      kernel_name_kernel_h <<< __gDim, __bDim, smem >>> (p1, p2, __memPoolDevice);
             */

            // Find all the child kernel calls in the kernel
            FunctionDecl* kernel = kernelCall->getDirectCallee();
            KernelCallFinder kcFinder(kernel);
            std::set<CUDAKernelCallExpr*> childKernelCalls = kcFinder.getKernelCalls();

            // Declare and initialize commonly used variables
            std::stringstream ss;
            CallExpr* config = kernelCall->getConfig();
            std::string gridDimConfig = toString(config->getArg(0));
            std::string blockDimConfig = toString(config->getArg(1));
            std::string smemConfig = toString(config->getArg(2));
            bool isSmemConfigExplicit = !dyn_cast<CXXDefaultArgExpr>(config->getArg(2));
            std::map<FunctionDecl*, std::vector<bool>> isScalarChildParam;
            std::map<FunctionDecl*, bool> isScalarChildBlockDim;
            std::map<FunctionDecl*, bool> isChildSmemConfigExplicit;
            std::map<FunctionDecl*, bool> isScalarChildSmemConfig;
            // Create a new scope to avoid name collisions
            ss << "{\n";

            // Create a memory pool
            ss << "static __MemPool __memPool(" << CompilerOptions::memoryPoolSize() << ");\n";
            ss << "__GridMemPool __memPoolHost(__memPool);\n";
            ss << "__GridMemPool __memPoolDevice = __memPoolHost;\n";

            // Store configurations in variables
            ss << "unsigned int __gDim = " << gridDimConfig << ";\n";
            ss << "unsigned int __bDim = " << blockDimConfig << ";\n";
            ss << "unsigned int __granularity = __GRANULARITY > __gDim ? __gDim : __GRANULARITY;\n";
            ss << "unsigned int __totalNumOfBuckets = (__gDim + __granularity - 1) / __granularity;\n";
            ss << "union scan_counter *_sc_ = __memPoolHost.grid_allocate<union scan_counter>(__totalNumOfBuckets);\n";
            ss << "unsigned int *aggregationGranularityCounterBucket = __memPoolHost.grid_allocate<unsigned int>(__totalNumOfBuckets);\n";
            ss << "cudaMemset(_sc_, 0, (sizeof(union scan_counter) + sizeof(unsigned int)) * __totalNumOfBuckets);\n";

            // Kernel call
            ss << kernel->getNameAsString() << "_kernel_h <<< __gDim, __bDim";
            if(isSmemConfigExplicit) {
                ss << ", " << smemConfig;
            }
            ss << " >>> (";
            for(unsigned int a = 0; a < kernelCall->getNumArgs(); ++a) {
                std::string arg = toString(kernelCall->getArg(a));
                ss << arg << ", "; // Original arguments
            }
            ss << "__memPoolDevice);\n"; // Configuration arrays

            // Close scope
            ss << "}\n";

            // Replace original call
            rewriter_.ReplaceText(SourceRange(kernelCall->getLocStart(), kernelCall->getLocEnd()), ss.str());

        }
    }

    return true;
}
