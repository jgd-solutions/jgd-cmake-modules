#include <iostream>
#include <single-exec-project/single-exec-project_config.hpp>
#include <single-exec-project/test.hpp>

int main() {
  using namespace single;
  return (test() == 0) && !data_dir.empty();
}
