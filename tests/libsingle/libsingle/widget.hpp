#pragma once

#include <libsingle/export_macros.hpp>

namespace single {

class LIBSINGLE_EXPORT Factory;

class Widget {
 private:
  int value{0};

  explicit Widget(const int value);

  friend Factory;

 public:
  Widget() = delete;

  constexpr int get_value() const noexcept { return this->value; }
};

}  // namespace single
