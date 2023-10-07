#include <many-exec/formatter/formats/internal_to_upper.hpp>
#include <many-exec/formatter/formats/upper_format.hpp>

namespace many {

char upper_format(const char c) noexcept { return to_upper(c); }

}  // namespace many
