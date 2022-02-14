#ifndef _KLAP_THRESHOLD_TRANSFORM_H
#define _KLAP_THRESHOLD_TRANSFORM_H

#include "clang/AST/AST.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Rewrite/Core/Rewriter.h"

#include <sstream>
#include <string>

#include "Analysis/Analyzer.h"

using namespace clang;

class  KernelSerializationTransform : public RecursiveASTVisitor<KernelSerializationTransform> {

    public:

        KernelSerializationTransform(Rewriter& rewriter, Analyzer& analyzer);

        bool VisitCallExpr(CallExpr *expr);

private:
        Rewriter &rewriter_;
        Analyzer &analyzer_;
        std::stringstream ss;
};

#endif
