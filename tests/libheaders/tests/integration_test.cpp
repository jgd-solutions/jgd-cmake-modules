#include <initializer_list>
#include <libheaders/equality.hpp>
#include <libheaders/sum.hpp>

int main()
{
  using namespace headers;

  const int result1 = sum(std::initializer_list{-4, -3, -2, -1, 0, 1, 2, 3, 4});
  const int result2 = sum(std::initializer_list{-100, 50, 50});
  const bool equal = is_equal(result1, result2);
  return equal ? 0 : 1;
}
