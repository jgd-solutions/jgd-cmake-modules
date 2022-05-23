#pragma once

namespace headers {

template <typename T>
requires(sizeof(T) <= sizeof(T&)) bool is_equal(const T first, const T second) {
  return first == second;
}

template <typename T>
requires(sizeof(T) > sizeof(T&)) bool is_equal(const T& first,
                                               const T& second) {
  return first == second;
}

}  // namespace headers
