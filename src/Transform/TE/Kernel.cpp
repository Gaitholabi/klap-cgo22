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


class ThreadExtractionTransformInternal : public ConstStmtVisitor<ThreadExtractionTransformInternal> {
public:
    ThreadExtractionTransformInternal(Rewriter& rewriter)
            : rewriter_(rewriter) {}

    void VisitMaterializeTemporaryExpr(const MaterializeTemporaryExpr* expr) {
        const Expr* sub = expr->GetTemporaryExpr();
        Visit(sub);
    }

    void VisitCXXConstructExpr(const CXXConstructExpr* E) {
        for(unsigned int a = 0; a < E->getNumArgs(); ++a) {
            if (!threadsDetected()) {
                const Expr* arg = E->getArg(0);
                Visit(arg);
            }
        }
    }

    void VisitCXXFunctionalCastExpr(const CXXFunctionalCastExpr* expr) {
        const Expr* sub = expr->getSubExpr();
        Visit(sub);
    }

    void VisitImplicitCastExpr(const ImplicitCastExpr* expr) {
        Visit(expr->getSubExpr());
    }

    void VisitCStyleCastExpr(const CStyleCastExpr* expr) {
        Visit(expr->getSubExpr());
    }

    void VisitMemberExpr(const MemberExpr* memberExpr) {
        ss << toString(memberExpr);
    }

    void VisitBinaryOperator(const BinaryOperator *BO) {
        if (BO->getOpcode() == BO_EQ) {
            return;
        }

        const Expr* rhs = BO->getRHS();
        const Expr* lhs = BO->getLHS();

        /**
        * if operator is division, we don't need to visit the RHS
        */
        if(BO->getOpcode() == BO_Div || BO->getOpcode() == BO_DivAssign) {
            foundDivision = true;
        }
        Visit(lhs);

        if (!dyn_cast<BinaryOperator>(rhs) && !dyn_cast<BinaryOperator>(lhs)) {
            const ImplicitCastExpr * lhse = dyn_cast<ImplicitCastExpr>(lhs);
            const ImplicitCastExpr * rhse = dyn_cast<ImplicitCastExpr>(rhs);
            if (lhse && rhse && rhse->getCastKind() != CK_IntegralCast && lhse->getCastKind() != CK_IntegralCast) {
                ss << BO->getOpcodeStr().str();
            }
        }
        if (!foundDivision || (BO->getOpcode() != BO_Div)) {
            Visit(rhs);
        }
    }

    void VisitParenExpr(const ParenExpr* E) {
        const Expr* sub = E->getSubExpr();
        Visit(sub);
    }

    void VisitCallExpr(const CallExpr* call) {
        for (auto I = call->arg_begin(), E = call->arg_end(); I != E; ++I) {
            Visit(*I);
        }
    }

    void VisitDeclRefExpr(const DeclRefExpr* E) {
        if (foundDivision) {
            std::string name = toString(E);
            ss << name;
        } else {
            const VarDecl* vdecl = dyn_cast<VarDecl>(E->getDecl());
            const Expr* init = vdecl->getInit();
            Visit(init);
        }
    }


    void VisitConditionalOperator(const ConditionalOperator* conditionalOperator) {
        Visit(conditionalOperator->getCond());
    }

    std::string getOutputSS() {
        return ss.str();
    }

    bool threadsDetected() {
        return foundDivision;
    }

private:
    Rewriter &rewriter_;
    std::stringstream ss;
    bool foundDivision = false;
};


ThreadExtractionTransform::ThreadExtractionTransform(Rewriter& rewriter, Analyzer& analyzer)
        : rewriter_(rewriter), analyzer_(analyzer) {}

bool ThreadExtractionTransform::VisitCallExpr(CallExpr *s) {
    if (CUDAKernelCallExpr * kernelCall = dyn_cast<CUDAKernelCallExpr>(s)) {
        if (analyzer_.isCallFromKernelCandidate(kernelCall)) {
            /**
             * Extract kernel config
             */
            Expr* gridDimConfig = kernelCall->getConfig()->getArg(0);
            Expr* blockDimConfig = kernelCall->getConfig()->getArg(1);
            std::string smemConfig = toString(kernelCall->getConfig()->getArg(2));
            bool isSmemConfigExplicit = !dyn_cast<CXXDefaultArgExpr>(kernelCall->getConfig()->getArg(2));

            /**
             * Extract number of threads
             */
            ThreadExtractionTransformInternal threadExtractionTransformInternal(rewriter_);
            threadExtractionTransformInternal.Visit(gridDimConfig);

            std::stringstream extractedVarsStream;
            std::string gridDimConfigString = toString(gridDimConfig);
            std::string blockDimConfigString = toString(blockDimConfig);

            /**
             * extract kernel config, to avoid side effects, grid dim config can be obtained as a function of threads
             */

            extractedVarsStream << "unsigned int __blockDimConfig =" << blockDimConfigString << "; \n";
            if (threadExtractionTransformInternal.threadsDetected()) {
                extractedVarsStream << "\nunsigned int __threads =" << threadExtractionTransformInternal.getOutputSS() << ";\n";
                extractedVarsStream << "unsigned int __gridDimConfig = (__threads + __blockDimConfig - 1) / __blockDimConfig; \n";
            } else {
                extractedVarsStream << "unsigned int __gridDimConfig =" << gridDimConfigString << ";\n";
                extractedVarsStream << "\nunsigned int __threads = __blockDimConfig * __gridDimConfig;\n";
            }
            rewriter_.InsertTextBefore(kernelCall->getSourceRange().getBegin(), extractedVarsStream.str());

            /**
             * rewrite kernel call
             */
            std::stringstream kernelRewriteStream;
            kernelRewriteStream << "<<<__gridDimConfig, __blockDimConfig";

            if (isSmemConfigExplicit) {
                kernelRewriteStream << "," << toString(kernelCall->getConfig()->getArg(2));
            }
            kernelRewriteStream << ">>>";

            SourceLocation beginExpr = kernelCall->getConfig()->getSourceRange().getBegin();
            SourceLocation endExpr = kernelCall->getConfig()->getSourceRange().getEnd();
            rewriter_.ReplaceText(SourceRange(beginExpr, endExpr), kernelRewriteStream.str());
        }
    }
    return true;
}
