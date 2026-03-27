// hello.cpp — minimal C++ program for cross-compilation smoke test
#include <cstdio>
#include <string>

int main() {
    std::string msg = "Hello from C++";
    printf("%s\n", msg.c_str());
    return 0;
}
