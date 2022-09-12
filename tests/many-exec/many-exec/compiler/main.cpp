#include <iostream>
#include <many-exec/compiler/compile.hpp>
#include <string>

int main(const int argc, const char* const argv[])
{
  if (argc == 0) {
    return 0;
  }

  for (const auto compiled : many::compile(argv[0])) {
    std::cout << compiled << ' ';
  }

  std::cout << std::endl;
}
