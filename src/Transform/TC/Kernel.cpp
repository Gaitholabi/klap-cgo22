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

class ThreadCoarseningTransformInternal : public RecursiveASTVisitor<ThreadCoarseningTransformInternal> {
public:
    ThreadCoarseningTransformInternal(Rewriter& rewriter)
            : rewriter_(rewriter) {}

            bool VisitMemberExpr(MemberExpr * memberExpr) {
                SourceLocation beginExpr = memberExpr->getLocStart();
                SourceLocation endExpr = memberExpr->getLocEnd();
                if(toString(memberExpr) == "blockIdx.__fetch_builtin_x") {
                    rewriter_.ReplaceText(SourceRange(beginExpr, endExpr), "___blockIdx_x");
                } else if (toString(memberExpr) == "gridDim.__fetch_builtin_x") {
                    rewriter_.ReplaceText(SourceRange(beginExpr, endExpr), "___gridDimConfig_C");
                }
                return true;
            }

private:
    Rewriter &rewriter_;
};
ThreadCoarseningTransform::ThreadCoarseningTransform(Rewriter& rewriter, Analyzer& analyzer)
        : rewriter_(rewriter), analyzer_(analyzer) {}

std::string ThreadCoarseningTransform::loopLocalityType() {
    if(CompilerOptions::transformType() == CompilerOptions::TC_1) {
        return "\nfor(unsigned int ___blockIdx_x = blockIdx.x; ___blockIdx_x < ___gridDimConfig_C;  ___blockIdx_x += gridDim.x) {\n";
    } else if(CompilerOptions::transformType() == CompilerOptions::TC_2) {
        return "\nfor(unsigned int ___blockIdx_x = blockIdx.x * __COARSE_FACTOR; ___blockIdx_x < min((blockIdx.x + 1) * __COARSE_FACTOR, ___gridDimConfig_C); ++___blockIdx_x)\n{";
    } else if(CompilerOptions::transformType() == CompilerOptions::TC_3) {
        return "\nfor(unsigned int __coarse_iterator = 0; __coarse_iterator < __COARSE_FACTOR; ++__coarse_iterator) {\n"
               "unsigned int ___blockIdx_x = blockIdx.x * __COARSE_FACTOR + __coarse_iterator;\n"
               "    if(___blockIdx_x < ___gridDimConfig_C) {\n";
    } else {
        assert(0 && "Unreachable");
    }
}

bool ThreadCoarseningTransform::VisitStmt(Stmt *s) {
    if (CUDAKernelCallExpr * kernelCall = dyn_cast<CUDAKernelCallExpr>(s)) {
        FunctionDecl *funcDecl = kernelCall->getDirectCallee();

        bool funcVisited = false;
        for ( auto &i : visited_) {
            if (i == funcDecl->getNameAsString()) {
                funcVisited = true;
                break;
            }
        }
        visited_.push_back(funcDecl->getNameAsString());

        if (!funcVisited) {
            // create new coarse function
            SourceLocation nameLoc = funcDecl->getNameInfo().getLoc();
            rewriter_.InsertTextBefore(nameLoc, "__kernel_coarse__");

            // add original grid dim parameter
            std::stringstream funcDeclArgumentStringStream;
            funcDeclArgumentStringStream << ", unsigned int ___gridDimConfig_C";
            SourceLocation endParamLoc = funcDecl->getParamDecl(funcDecl->getNumParams() - 1)->getSourceRange().getEnd();
            rewriter_.InsertTextAfterToken(endParamLoc, funcDeclArgumentStringStream.str());
        }

        if (analyzer_.isCallFromKernelCandidate(kernelCall)) {

            /**
             * Update call signature
             */
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
            rewriteGridDimConfigString<<"(___gridDimConfig_C + __COARSE_FACTOR - 1)/ __COARSE_FACTOR ";
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

            if (!funcVisited) {
                /**
                 * rewrite every instance of blockIdx to local variable
                 */
                ThreadCoarseningTransformInternal threadCoarseningTransformInternal(rewriter_);
                threadCoarseningTransformInternal.TraverseDecl(funcDecl);

                /**
                 * add coarsening loop on top of unvisited functions
                 */
                std::stringstream coarseningLoopStringStream;
                coarseningLoopStringStream << loopLocalityType();
                SourceLocation functionBodyStartLocation = funcDecl->getBody()->getSourceRange().getBegin();
                rewriter_.InsertTextAfterToken(functionBodyStartLocation, coarseningLoopStringStream.str());

                std::stringstream coarseningLoopEndStringStream;
                coarseningLoopEndStringStream << "\n }";
                if(CompilerOptions::transformType() == CompilerOptions::TC_3) {
                    coarseningLoopEndStringStream << "}\n";
                }
                SourceLocation functionBodyEndLocation = funcDecl->getBody()->getSourceRange().getEnd();
                rewriter_.InsertTextAfterToken(functionBodyEndLocation, coarseningLoopEndStringStream.str());
            }

        }

    }

    return true;
}

bool ThreadCoarseningTransform::VisitFunctionDecl(FunctionDecl *f) {
    if(!f->isImplicit() && !f->getAttr<CUDAGlobalAttr>()) {
        SourceManager& sm = rewriter_.getSourceMgr();
        if(sm.isInMainFile(sm.getExpansionLoc(f->getLocStart()))) {
            rewriter_.RemoveText(SourceRange(f->getLocStart(), f->getLocEnd()));
        }
    }
    return true;
}
