#pragma once

#include <cctype>
#include <many-exec/shared.hpp>
#include <string_view>

namespace many {

auto reformat(const std::string_view in)
{
  return apply_to_string(in, [](auto c) { return std::toupper(static_cast<unsigned char>(c)); });
}

}  // namespace many
