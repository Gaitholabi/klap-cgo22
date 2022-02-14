#ifndef KLAP_THREADEXTRACTIONTRANSFORM_H
#define KLAP_THREADEXTRACTIONTRANSFORM_H

#include "clang/AST/AST.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Rewrite/Core/Rewriter.h"

#include "Analysis/Analyzer.h"

using namespace clang;

class  ThreadExtractionTransform : public RecursiveASTVisitor<ThreadExtractionTransform> {

public:

    ThreadExtractionTransform(Rewriter& rewriter, Analyzer& analyzer);

    bool VisitCallExpr(CallExpr *s);

private:
    Rewriter &rewriter_;
    Analyzer &analyzer_;
};


#endif
