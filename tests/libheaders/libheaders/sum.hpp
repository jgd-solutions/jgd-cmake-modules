#pragma once

#include <concepts>
#include <ranges>

namespace headers {

template <std::ranges::input_range Rng, typename Val = std::ranges::range_value_t<Rng>>
requires requires(Val first, const Val second) {
  {
    first + second
  } -> std::same_as<Val>;
  first = second;
}
Val sum(const Rng& rng)
{
  int sum{};
  for (const auto v : rng) {
    sum = sum + v;
  }
  return sum;
}

}  // namespace headers
