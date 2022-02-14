
#ifndef KLAP_THRESHOLDTRANSFORM_H
#define KLAP_THRESHOLDTRANSFORM_H

#include "clang/AST/AST.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Rewrite/Core/Rewriter.h"

#include "Analysis/Analyzer.h"

using namespace clang;

class KernelThresholdTransform  : public RecursiveASTVisitor<KernelThresholdTransform> {

public:

    KernelThresholdTransform(Rewriter& rewriter, Analyzer& analyzer);
    bool VisitCallExpr(CallExpr *s);

private:
    Rewriter &rewriter_;
    Analyzer &analyzer_;
};


#endif
