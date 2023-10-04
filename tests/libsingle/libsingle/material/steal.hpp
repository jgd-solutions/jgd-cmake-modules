#pragma once

namespace single {

namespace detail {
  /*!
     * Returns the steal density from a function so this nested directory can
     * have some definitions outside the header.
     *
     * Factory object represents
   */
  [[nodiscard]] int query_steal_density();
}

inline constexpr int steal_density = query_steal_density();

}
