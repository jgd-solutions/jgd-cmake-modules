#include <daemon/exec.hpp>
#include <libdaemon/protocol.hpp>

int daemon::exec()
{
  const Protocol protoc{};
  return protoc.field();
}
