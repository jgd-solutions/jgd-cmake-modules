#include <daemon/exec.hpp>

int main()
{
  // Testing functionality of the EXECUTABLE by using its associated library, <target-name>-library.
  // This is different than the supplementary library we're creating in this project example. The
  // first one contains all the main executable functionality and is private to the project; present
  // only for testing.  The supplementary library is another explicit library offered with the
  // project that's exported and installed. This library, libdaemon, is not used here.
  return daemon::exec();
}
