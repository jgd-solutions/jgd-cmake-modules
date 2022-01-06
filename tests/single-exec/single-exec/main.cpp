#include <iostream>
#include <single-exec/single-exec_config.hpp>
#include <single-exec/test.hpp>

int main() {
  using namespace single;
  return test() || data_dir.empty();
}
