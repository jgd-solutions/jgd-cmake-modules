#include <cctype>
#include <many-exec/formatter/formats/internal_to_upper.hpp>

namespace many {

char to_upper(const char c) noexcept
{
  return static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
}

}  // namespace many
