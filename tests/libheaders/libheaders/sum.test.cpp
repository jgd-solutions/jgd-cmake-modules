#include <initializer_list>
#include <libheaders/sum.hpp>

int main()
{
  using namespace headers;
  auto vals = {-5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5};
  const auto result = sum(vals);  // 0
  return result;
}
