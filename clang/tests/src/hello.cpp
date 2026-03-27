#include <iostream>
#include <vector>
#include <string>
int main() {
    std::vector<std::string> v = {"Hello", "from", "C++"};
    for (const auto& s : v) std::cout << s << " ";
    std::cout << std::endl;
    return 0;
}
