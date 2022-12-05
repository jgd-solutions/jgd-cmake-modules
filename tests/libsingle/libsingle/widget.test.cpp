#include <cassert>
#include <libsingle/factory.hpp>
#include <libsingle/widget.hpp>

int main()
{
  using namespace single;
  Factory f{};
  const auto w = f.manufacture();
  assert(w.get_value() == 0);
  assert(w.get_stamp().size() != 0);
}
