#pragma once

#include <bitset>
#include <many-exec/shared.hpp>
#include <string_view>

namespace many {

auto compile(const std::string_view in)
{
  using Char = std::string_view::value_type;
  return apply_to_string(in, [](const Char c) {
    const auto as_num = static_cast<unsigned char>(c);
    const auto bits = std::bitset<sizeof(Char) * 8>(as_num);
    return bits.to_string();
  });
}

}  // namespace many
