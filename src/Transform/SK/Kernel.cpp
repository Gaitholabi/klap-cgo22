#include "clang/AST/AST.h"
#include "clang/Rewrite/Core/Rewriter.h"
#include "llvm/Support/raw_ostream.h"
#include <iostream>

#include <sstream>
#include <string>

#include <regex>
#include "Driver/CompilerOptions.h"
#include "Kernel.h"
#include "Utils/Utils.h"

using namespace clang;

KernelSerializationTransform::KernelSerializationTransform(Rewriter& rewriter, Analyzer& analyzer)
        : rewriter_(rewriter), analyzer_(analyzer) {}

bool KernelSerializationTransform::VisitCallExpr(CallExpr *callExpr) {

    if (CUDAKernelCallExpr * kernelCall = dyn_cast<CUDAKernelCallExpr>(callExpr)) {
        if (analyzer_.isCallFromKernelCandidate(kernelCall)) {
            FunctionDecl * funcDecl = kernelCall->getDirectCallee();
            if(funcDecl->getAttr<CUDAGlobalAttr>() && funcDecl->doesThisDeclarationHaveABody()) {
                std::string bodyString = toString(funcDecl->getBody());
                std::string replacedBlockId = std::regex_replace(bodyString, std::regex("blockIdx.x"), "__blockId");
                std::string replacedThreadId = std::regex_replace(replacedBlockId, std::regex("threadIdx.x"), "__threadId");
                std::string replacedBlockDim = std::regex_replace(replacedThreadId, std::regex("blockDim.x"), "__blockDimConfig");
                std::string replaceGridDim = std::regex_replace(replacedBlockDim, std::regex("gridDim.x"), "__gridDimConfig");
                /**
                 * Duplicate kernel with a serial copy, replacing uses of CUDA indexing
                 */
                ss << "\n#ifndef _KLAP_KERNEL_SERIALIZE_TRANSFORM_H" << funcDecl->getNameAsString() << "\n"
                       "#define _KLAP_KERNEL_SERIALIZE_TRANSFORM_H" << funcDecl->getNameAsString() << "\n"
                        "#define _Bool bool \n";
                ss << "\n__device__ __forceinline__ " << funcDecl->getReturnType().getAsString() << " " << funcDecl->getNameAsString() << "__serial(";
                for (unsigned int i = 0; i < funcDecl->getNumParams(); i++) {
                    ParmVarDecl *param = funcDecl->getParamDecl(i);
                    ss << param->getType().getAsString() << " " << param->getQualifiedNameAsString() << ",";
                }
                ss << "unsigned int __blockDimConfig, unsigned int __gridDimConfig){\n";
                ss << "for (unsigned __blockId = 0; __blockId < __gridDimConfig; ++__blockId) {\n"
                      "for (unsigned int __threadId = 0; __threadId < __blockDimConfig; ++__threadId)\n";

                ss << replaceGridDim;
                ss << "}\n}";
                ss << "\n#endif";

                SourceLocation functionBodyEndLocation = funcDecl->getBody()->getSourceRange().getEnd();
                rewriter_.InsertTextAfterToken(functionBodyEndLocation, ss.str());
            }
        }
    }
    return true;
}
