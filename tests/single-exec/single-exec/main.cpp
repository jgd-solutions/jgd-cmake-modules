#include <iostream>
#include <single-exec/single-exec_config.hpp>
#include <single-exec/test.hpp>

int main() {
  using namespace single;
  return (test() == 0) && !data_dir.empty();
}
