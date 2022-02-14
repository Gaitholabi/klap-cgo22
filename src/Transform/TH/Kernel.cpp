
#include "clang/AST/AST.h"
#include "clang/Rewrite/Core/Rewriter.h"
#include "llvm/Support/raw_ostream.h"
#include <iostream>
#include <sstream>
#include <string>

#include "Driver/CompilerOptions.h"
#include "Kernel.h"
#include "Utils/Utils.h"

using namespace clang;

KernelThresholdTransform::KernelThresholdTransform(Rewriter& rewriter, Analyzer& analyzer)
        : rewriter_(rewriter), analyzer_(analyzer) {}

bool KernelThresholdTransform::VisitCallExpr(CallExpr *s) {
    if (CUDAKernelCallExpr * kernelCall = dyn_cast<CUDAKernelCallExpr>(s)) {
        if (analyzer_.isCallFromKernelCandidate(kernelCall)) {

            /**
             * Add threshold guard statement
             */
            std::stringstream thresholdGuardStringStream;
            thresholdGuardStringStream << "if (__threads >= __THRESHOLD_T) {";
            rewriter_.InsertTextBefore(kernelCall->getSourceRange().getBegin(), thresholdGuardStringStream.str());

            /**
             * Call serial kernel with copy of indexing parameters
             */
            std::stringstream serializedKenelCallStringStream;
            serializedKenelCallStringStream << "} \n else {\n " << s->getDirectCallee()->getNameAsString() << "__serial(";
            for(auto argument = s->arg_begin(); argument != s->arg_end(); ++argument) {
                serializedKenelCallStringStream << toString(*argument) << ", ";
            }
            serializedKenelCallStringStream << "__blockDimConfig, __gridDimConfig); \n }";
            rewriter_.InsertTextAfterToken(s->getEndLoc().getLocWithOffset(2), serializedKenelCallStringStream.str());
        }
    }
    return true;
}

