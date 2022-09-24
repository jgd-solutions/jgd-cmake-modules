#include <assert.h>
#include <libcstr/cstr.h>
#include <stddef.h>
#include <string.h>

int main()
{
  // create
  Cstr first = cstr_create("first string");
  Cstr second = cstr_create("second string");
  assert(first.size == 12);
  assert(second.size == 13);
  assert(first.data[first.size] == '\0');
  assert(second.data[second.size] == '\0');
  assert(first.capacity >= 13);  // capacity includes room for null-char
  assert(second.capacity >= 14);

  // append
  cstr_append(&first, 's');
  assert(first.size == 13);
  cstr_append(&first, 's');
  assert(first.size == 14);

  // at
  assert(*cstr_at(&first, 0) == 'f');
  assert(*cstr_at(&first, 12) == 's');
  assert(*cstr_at(&second, 0) == 's');
  assert(*cstr_at(&second, 12) == 'g');

  *cstr_at(&first, 0) = 'F';
  *cstr_at(&first, 6) = 'S';
  assert(first.data[0] == 'F');
  assert(first.data[6] == 'S');

  // reserve
  cstr_reserve(&first, 20);
  assert(first.capacity >= 20);

  const size_t second_capacity = second.capacity;
  cstr_reserve(&second, second_capacity - 1);
  assert(second_capacity == second.capacity);  // no change

  // copy
  cstr_copy(&second, &first);
  assert(second.capacity >= first.capacity);
  assert(second.size == first.size);
  assert(strcmp(second.data, first.data) == 0);

  // destroy
  cstr_destroy(&first);
  cstr_destroy(&second);
  assert(first.data == NULL);
  assert(first.size == 0);
  assert(first.capacity == 0);
  assert(second.data == NULL);
  assert(second.size == 0);
  assert(second.capacity == 0);
}
