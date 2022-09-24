#pragma once

#include <stddef.h>

typedef struct Cstr {
  char* data;
  size_t size;
  size_t capacity;
} Cstr;

Cstr cstr_create(const char* init);
void cstr_destroy(Cstr*);

void cstr_reserve(Cstr*, size_t capacity);
char* cstr_at(const Cstr*, ptrdiff_t);
void cstr_append(Cstr*, char);
void cstr_copy(Cstr* to, const Cstr* from);
