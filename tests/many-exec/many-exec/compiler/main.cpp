#include <iostream>
#include <many-exec/compiler/compile.hpp>
#include <many-exec/many_exec_config.hpp>

int main(const int argc, const char* const argv[])
{
  if (argc == 0) {
    return 0;
  }

  std::cout << "Using version " << many::version << '\n';

  for (const auto compiled : many::compile(argv[0])) {
    std::cout << compiled << ' ';
  }

  std::cout << std::endl;
}
