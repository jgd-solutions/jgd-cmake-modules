#include <many-exec/compiler/compile.hpp>
#include <many-exec/formatter/reformat.hpp>
#include <many-exec/many-exec_config.hpp>

int main()
{
  // just some random stuff to verify config header was created and tests are run
  return many::compile("first").empty() || many::reformat("second").empty()
         || many::data_dir.empty();
}
