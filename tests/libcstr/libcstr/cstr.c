#include <libcstr/cstr.h>
#include <stdlib.h>
#include <string.h>

static const size_t growth_rate = 2;

static void _strcpy(char *restrict dest, const char *restrict src) {
#ifdef _MSC_VER
  #pragma warning(push)
#pragma warning(disable : 4996)
#endif

  strcpy(dest, src);

#ifdef _MSC_VER
#pragma warning(pop)
#endif
}

Cstr cstr_create(const char* const init)
{
  const size_t size = strlen(init);
  const size_t capacity = size * growth_rate + 1;
  char* const data = malloc(capacity);

  _strcpy(data, init);
  data[size] = '\0';

  Cstr result = {.data = data, .capacity = capacity, .size = size};
  return result;
}

void cstr_destroy(Cstr* const str)
{
  free(str->data);
  str->data = NULL;
  str->capacity = 0;
  str->size = 0;
}

void cstr_reserve(Cstr* const str, const size_t capacity)
{
  if (str->capacity < capacity) {
    str->capacity = capacity * growth_rate + 1;
    str->data = realloc(str->data, str->capacity);
  }
}

char* cstr_at(const Cstr* const str, const ptrdiff_t idx) { return str->data + idx; }

void cstr_append(Cstr* const str, char c)
{
  cstr_reserve(str, str->size + 1);
  str->data[str->size] = c;
  str->data[str->size + 1] = '\0';
  ++str->size;
}

void cstr_copy(Cstr* to, const Cstr* from)
{
  cstr_reserve(to, from->size);
  _strcpy(to->data, from->data);
  to->size = from->size;
}
