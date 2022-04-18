#pragma once

#include <libsingle/export_macros.hpp>
#include <libsingle/widget.hpp>

namespace single {

class LIBSINGLE_EXPORT Factory {
 private:
  int factory_num{0};

 public:
  Factory() = default;

  explicit Factory(const int factory_num);

  Widget manufacture(const int scale = 1) const noexcept;
};

}  // namespace single
