#pragma once

#include <concepts>
#include <ranges>
#include <string_view>

namespace many {

template <std::invocable<const std::string_view::value_type> Foo>
auto apply_to_string(const std::string_view in, Foo&& f)
{
  const auto applied = in | std::ranges::views::transform(std::forward<Foo>(f));
  return applied;
}

}  // namespace many
