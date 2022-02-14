#include "clang/AST/AST.h"
#include "clang/Rewrite/Core/Rewriter.h"
#include "llvm/Support/raw_ostream.h"
#include <iostream>

#include <sstream>
#include <string>

#include "Driver/CompilerOptions.h"
#include "Host.h"
#include "Utils/Utils.h"

using namespace clang;

ThreadCoarseningHostTransform::ThreadCoarseningHostTransform(Rewriter& rewriter, Analyzer& analyzer)
        : rewriter_(rewriter), analyzer_(analyzer) {}

bool ThreadCoarseningHostTransform::VisitStmt(Stmt *s) {

    if(CUDAKernelCallExpr* kernelCall = dyn_cast<CUDAKernelCallExpr>(s)) {
        if (analyzer_.isCallFromHostCandidate(kernelCall)) {
            SourceLocation kernelCallLoc = kernelCall->getBeginLoc();
            rewriter_.InsertTextBefore(kernelCallLoc, "__kernel_coarse__");

            /**
             * Extract grid dim
             */
            Expr *gridDimConfig = kernelCall->getConfig()->getArg(0);
            std::string gridDimConfigString = toString(gridDimConfig);
            std::stringstream gridDimConfigStringStream;
            gridDimConfigStringStream << "unsigned int ___gridDimConfig_C =" << gridDimConfigString << "; \n";
            SourceLocation beginParamLoc = kernelCall->getSourceRange().getBegin();
            rewriter_.InsertTextBefore(beginParamLoc, gridDimConfigStringStream.str());

            /**
             * rewrite grid config with coarse factor
             */
            std::stringstream rewriteGridDimConfigString;
            rewriteGridDimConfigString<<"___gridDimConfig_C";
            SourceLocation beginExpr = gridDimConfig->getSourceRange().getBegin();
            SourceLocation endExpr = gridDimConfig->getSourceRange().getEnd();
            rewriter_.ReplaceText(SourceRange(beginExpr, endExpr), rewriteGridDimConfigString.str());

            /**
             * pass original grid dim as a parameter to new kernels
             */
            std::stringstream gridDimConfigArgumentString;
            gridDimConfigArgumentString<<", ___gridDimConfig_C";
            SourceLocation kernelParamLoc = kernelCall->getArg(kernelCall->getNumArgs() - 1)->getSourceRange().getEnd();
            rewriter_.InsertTextAfterToken(kernelParamLoc, gridDimConfigArgumentString.str());

        }
    }

    return true;
}