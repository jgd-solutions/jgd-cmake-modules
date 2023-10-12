#include <libsingle/factory.hpp>
#include <libsingle/material/steal.hpp>

namespace single {

Factory::Factory(const int factory_num) : factory_num{factory_num} {}

Widget Factory::manufacture(const int scale) const noexcept
{
  return Widget(this->factory_num * scale * query_steal_density());
}

}  // namespace single
