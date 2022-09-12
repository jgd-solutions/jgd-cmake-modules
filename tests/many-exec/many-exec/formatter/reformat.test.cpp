#include <algorithm>
#include <many-exec/formatter/reformat.hpp>
#include <string_view>

int main()
{
  using namespace std::literals::string_view_literals;
  const auto are_equal = std::ranges::equal(many::reformat("hello"), "HELLO"sv);

  return static_cast<int>(!are_equal);
}
