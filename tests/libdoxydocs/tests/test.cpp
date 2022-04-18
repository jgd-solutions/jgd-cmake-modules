#include <libdoxydocs/factory.hpp>

int main() {
  using namespace doxydocs;
  Factory f{};
  const auto w = f.manufacture();
  return w.get_value();
}
