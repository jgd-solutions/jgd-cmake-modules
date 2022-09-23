#include <libcomponents/extra/extra.hpp>
#include <libcomponents/extra/extra_config.hpp>
#include <libcomponents/extra/more.hpp>

int components::more() { return extra() + can_find_configured_variable; }
