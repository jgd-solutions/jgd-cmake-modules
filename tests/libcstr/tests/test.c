#include <libcstr/cstr.h>

int main()
{
  Cstr str = cstr_create("a string");
  cstr_destroy(&str);
  return (int)(str.size);
}
