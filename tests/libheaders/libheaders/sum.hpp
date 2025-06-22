#pragma once

#include <concepts>
#include <ranges>

namespace headers {

template <std::ranges::input_range Rng>
requires(std::integral<std::ranges::range_value_t<Rng>>)
[[nodiscard]] std::ranges::range_value_t<Rng> sum(const Rng& rng)
{
  std::ranges::range_value_t<Rng> sum{};
  for (const auto v : rng) {
    sum += v;
  }
  return sum;
}

}  // namespace headers
