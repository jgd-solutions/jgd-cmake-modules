#pragma once

#include <many-exec/formatter/formats/upper_format.hpp>
#include <many-exec/shared.hpp>
#include <string_view>

namespace many {

auto reformat(const std::string_view in) { return apply_to_string(in, upper_format); }

}  // namespace many
