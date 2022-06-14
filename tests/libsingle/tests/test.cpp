#include <libsingle/factory.hpp>

int main()
{
  using namespace single;
  Factory f{};
  const auto w = f.manufacture();
  return w.get_value();
}
