#include <libcomponents/core/private/private.hpp>
#include <libcomponents/core/reader.hpp>
#include <libcomponents/libcomponents_config.hpp>

int components::reader() { return version.empty() || private_foo(); }
