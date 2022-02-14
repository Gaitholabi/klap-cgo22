//
// Created by Ghaith Olabi on 8/15/20.
//

#ifndef KLAP_THREAD_COARSE_HOST_TRANSFORM_H
#define KLAP_THREAD_COARSE_HOST_TRANSFORM_H

#include "clang/AST/AST.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Rewrite/Core/Rewriter.h"

#include "Analysis/Analyzer.h"

using namespace clang;

class  ThreadCoarseningHostTransform : public RecursiveASTVisitor<ThreadCoarseningHostTransform> {

public:

    ThreadCoarseningHostTransform(Rewriter& rewriter, Analyzer& analyzer);

    bool VisitStmt(Stmt *s);

private:
    Rewriter &rewriter_;
    Analyzer &analyzer_;
};

#endif
