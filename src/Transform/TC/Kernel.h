#ifndef KLAP_THREADCOARSEN_H
#define KLAP_THREADCOARSEN_H

#include "clang/AST/AST.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Rewrite/Core/Rewriter.h"

#include "Analysis/Analyzer.h"

using namespace clang;

class  ThreadCoarseningTransform : public RecursiveASTVisitor<ThreadCoarseningTransform> {

public:

    ThreadCoarseningTransform(Rewriter& rewriter, Analyzer& analyzer);

    bool VisitStmt(Stmt *s);

    bool VisitFunctionDecl(FunctionDecl *f);

private:
    Rewriter &rewriter_;
    Analyzer &analyzer_;
    std::vector<std::string> visited_;
    std::string loopLocalityType();

};


#endif
