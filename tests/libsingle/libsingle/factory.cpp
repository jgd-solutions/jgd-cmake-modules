#include <libsingle/factory.hpp>
#include <libsingle/steal.hpp>

namespace single {

Factory::Factory(const int factory_num) : factory_num{factory_num} {}

Widget Factory::manufacture(const int scale) const noexcept
{
  return Widget(this->factory_num * scale * steal_density);
}

}  // namespace single
