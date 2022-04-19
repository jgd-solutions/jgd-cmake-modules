#include <libclangformat/core/reader.hpp>
#include <libclangformat/extra/extra.hpp>
#include <libclangformat/extra/more.hpp>

int main() {
  using namespace clangformat;
  return reader() || extra() || more();
}
