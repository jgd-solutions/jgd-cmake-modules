#include <iostream>
#include <many-exec/formatter/reformat.hpp>

int main(const int argc, const char* const argv[])
{
  if (argc == 0) {
    return 0;
  }

  for (const auto formatted : many::reformat(argv[0])) {
    std::cout << formatted << ' ';
  }

  std::cout << std::endl;
}
