#include <cerrno>

import daemon.exec;
import daemon.exec_library;

int main()
{
  using namespace daemon;
  if (has_feature_A && has_feature_B) {
    return exec();
  }
  else {
    return EPROTONOSUPPORT;
  }
}
