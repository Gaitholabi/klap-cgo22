/*
 *  Copyright (c) 2018 IMPACT Research Group, University of Illinois.
 *  All rights reserved.
 *
 *  This file is covered by the LICENSE.txt license file in the root directory.
 *
 */

#include "llvm/Support/raw_ostream.h"

#include "CompilerOptions.h"

llvm::cl::OptionCategory CompilerOptions::KLAPCategory("Kernel Launch Aggregation & Promotion (KLAP) options");

static llvm::cl::opt<std::string>
transformTypeOp("t",
        llvm::cl::desc("Transformation type (de, aw, ab, ag, dag, th, te, sk, tc1, tc2, tc3)"),
        llvm::cl::cat(CompilerOptions::KLAPCategory));

static llvm::cl::opt<std::string>
outFileNameOp("o",
        llvm::cl::desc("Output file name"),
        llvm::cl::cat(CompilerOptions::KLAPCategory));

static llvm::cl::opt<unsigned long long>
memPoolSizeOp("m",
        llvm::cl::desc("Memory pool size"),
        llvm::cl::init(1 << 30),
        llvm::cl::cat(CompilerOptions::KLAPCategory));

static llvm::cl::opt<bool>
useAtomicsBasedScanOp("a",
        llvm::cl::desc("Use atomics-based scan"),
        llvm::cl::init(true),
        llvm::cl::cat(CompilerOptions::KLAPCategory));

static llvm::cl::opt<bool>
scalarizeInvariantParametersOp("s",
        llvm::cl::desc("Scalairze invariant parameters"),
        llvm::cl::init(true),
        llvm::cl::cat(CompilerOptions::KLAPCategory));

static llvm::cl::opt<bool>
scalarizeInvariantConfigurationsOp("b",
        llvm::cl::desc("Scalairze invariant configurations"),
        llvm::cl::init(true),
        llvm::cl::cat(CompilerOptions::KLAPCategory));

static llvm::cl::opt<bool>
aggregateMallocFreeOp("g",
        llvm::cl::desc("Aggregate cudaMalloc/cudaFree"),
        llvm::cl::init(true),
        llvm::cl::cat(CompilerOptions::KLAPCategory));

CompilerOptions::TransformType CompilerOptions::transformType() {
    if(transformTypeOp == "de") {
        return DE;
    } else if(transformTypeOp == "aw") {
        return AW;
    } else if (transformTypeOp == "ab") {
        return AB;
    } else if (transformTypeOp == "ag") {
        return AG;
    } else if (transformTypeOp == "dag") {
        return DAG;
    } else if (transformTypeOp == "th") {
        return TH;
    } else if (transformTypeOp == "te") {
        return TE;
    } else if (transformTypeOp == "sk") {
        return SK;
    } else if (transformTypeOp == "tc1") {
        return TC_1;
    } else if (transformTypeOp == "tc2") {
        return TC_2;
    } else if (transformTypeOp == "tc3") {
        return TC_3;
    } else if (transformTypeOp.empty()) {
        llvm::errs() << "No transform type provided.\n";
        llvm::errs() << "Use the -t option to provide a transform type.\n";
        llvm::errs() << "Possible values: de, aw, ab, ag, dag, th, te, sk, tc.\n";
        exit(0);
    } else {
        llvm::errs() << "Unrecognized transformation type: " << transformTypeOp << ".\n";
        llvm::errs() << "Possible values: de, aw, ab, ag, dag, th, te, sk, tc.\n";
        exit(0);
    }
}

void CompilerOptions::writeToOutputFile(Rewriter& rewriter, CompilerOptions::WriteMode mode) {
    SourceManager &SM = rewriter.getSourceMgr();
    if(outFileNameOp != "") {
        std::error_code EC;
        llvm::sys::fs::OpenFlags flags = llvm::sys::fs::F_Text;
        if(mode == APPEND) {
            flags |= llvm::sys::fs::F_Append;
        }
        llvm::raw_fd_ostream FileStream(outFileNameOp, EC, flags);
        if(mode == OVERWRITE && (transformType() == AW || transformType() == AB || transformType() == AG || transformType() == DAG)) {
            FileStream << "#include \"klap.h\"\n";
        } else if (transformType() == TC_1 || transformType() == TC_2 || transformType() == TC_3 || transformType() == TH || transformType() == SK) {
            FileStream << "#include \"factors.h\"\n";
        }
        if (EC) {
            llvm::errs() << "Error: Could not write to " << EC.message() << "\n";
        } else {
            rewriter.getEditBuffer(SM.getMainFileID()).write(FileStream);
        }
    } else {
        rewriter.getEditBuffer(SM.getMainFileID()).write(llvm::outs());
    }
}

unsigned long long CompilerOptions::memoryPoolSize() {
    return memPoolSizeOp;
}

bool CompilerOptions::useAtomicsBasedScan() {
    return useAtomicsBasedScanOp;
}

bool CompilerOptions::scalarizeInvariantParameters() {
    return scalarizeInvariantParametersOp;
}

bool CompilerOptions::scalarizeInvariantConfigurations() {
    return scalarizeInvariantConfigurationsOp;
}

bool CompilerOptions::aggregateMallocFree() {
    return aggregateMallocFreeOp;
}

