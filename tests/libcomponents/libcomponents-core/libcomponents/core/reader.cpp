#include <libcomponents/core/private/private.hpp>
#include <libcomponents/core/reader.hpp>
#include <libcomponents/libcomponents_config.hpp>

int components::reader() { return data_dir.empty() || private_foo(); }
