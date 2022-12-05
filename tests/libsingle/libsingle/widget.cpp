#include <libsingle/libsingle_config.hpp>
#include <libsingle/steal.hpp>
#include <libsingle/widget.hpp>
#include <string>

namespace single {

Widget::Widget(const int value) : value{value} {}
std::string Widget::get_stamp() const { return std::to_string(value) + " @ " + version; }

}  // namespace single
