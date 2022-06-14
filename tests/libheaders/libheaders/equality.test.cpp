#include <libheaders/equality.hpp>

int main()
{
  using namespace headers;
  const auto correct = !is_equal(1, 2) && is_equal(6, 6) && !is_equal(5.5, 7.0);
  return correct ? 0 : 1;
}
