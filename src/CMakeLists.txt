
set(LLVM_LINK_COMPONENTS
        Support
        )

add_clang_executable(klap
        Analysis/Analyzer.cpp
        Analysis/InvarianceAnalyzer.cpp
        Analysis/KernelCallFinder.cpp
        Analysis/SpecialStmtFinder.cpp
        Analysis/TransformCandidateFinder.cpp
        Driver/Driver.cpp
        Driver/CompilerOptions.cpp
        Transform/DE/Kernel.cpp
        Transform/AWB/Kernel.cpp
        Transform/AWB/Host.cpp
        Transform/AG/Kernel.cpp
        Transform/AG/Host.cpp
        Transform/DAG/Kernel.cpp
        Transform/DAG/Host.cpp
        Utils/Utils.cpp
        Transform/SK/Kernel.cpp
        Transform/TE/Kernel.cpp
        Transform/TH/Kernel.cpp
        Transform/TC/Kernel.cpp
        Transform/TC/Host.cpp
        )
target_link_libraries(klap
        PRIVATE
        clangTooling
        clangBasic
        clangASTMatchers
        )

install(TARGETS klap
        RUNTIME DESTINATION bin)
