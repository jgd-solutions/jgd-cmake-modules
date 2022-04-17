#include <single-exec/exec.hpp>
#include <single-exec/single-exec_config.hpp>

int main() {
  using namespace single;
  return exec() || data_dir.empty();
}
