#include <libdaemon/protocol.hpp>

int main () {
  daemon::Protocol protoc{};
  return protoc.field();
}