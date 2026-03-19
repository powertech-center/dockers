// use_llvm.cpp — test that LLVM development headers are accessible
#include <llvm/Support/raw_ostream.h>

int main() {
    llvm::outs() << "LLVM dev headers work\n";
    return 0;
}
