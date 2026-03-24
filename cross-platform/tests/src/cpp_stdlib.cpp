// cpp_stdlib.cpp — test that C++ standard library works (vector, algorithm)
#include <vector>
#include <algorithm>
#include <cstdio>

int main() {
    std::vector<int> v = {3, 1, 4, 1, 5, 9};
    std::sort(v.begin(), v.end());
    for (int x : v) {
        printf("%d ", x);
    }
    printf("\n");
    return 0;
}
