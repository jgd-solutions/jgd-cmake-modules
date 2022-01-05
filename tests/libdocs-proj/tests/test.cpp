#include <libdocs-proj/factory.hpp>

int main() {
  using namespace docsproj;
  Factory f{};
  const auto w = f.manufacture();
  return w.get_value();
}
