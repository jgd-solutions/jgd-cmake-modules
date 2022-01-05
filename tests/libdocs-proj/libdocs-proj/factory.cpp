#include <libdocs-proj/factory.hpp>

using namespace docsproj;

Factory::Factory(const int factory_num) : factory_num{factory_num} {}

Widget Factory::manufacture(const int scale) const noexcept {
  return Widget(this->factory_num * scale);
}
