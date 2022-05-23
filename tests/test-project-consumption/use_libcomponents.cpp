#include <libcomponents/core/reader.hpp>
#include <libcomponents/extra/extra.hpp>
#include <libcomponents/extra/more.hpp>

int main() {
  using namespace components;
  return reader() || extra() || more();
}
