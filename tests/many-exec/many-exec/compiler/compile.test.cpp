#include <algorithm>
#include <array>
#include <many-exec/compiler/compile.hpp>
#include <string_view>

int main()
{
  constexpr std::array<std::string_view, 2> bin_result{"01101000", "01101001"};
  const auto are_equal = std::ranges::equal(many::compile("hi"), bin_result);
  return static_cast<int>(!are_equal);
}
