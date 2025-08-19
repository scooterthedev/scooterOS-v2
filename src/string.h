#ifndef STRING_H
#define STRING_H

#include <stddef.h>

// String manipulation functions
int strlen(const char* str);
int strcmp(const char* str1, const char* str2);
int strncmp(const char* str1, const char* str2, size_t n);
char* strcpy(char* dest, const char* src);
char* strncpy(char* dest, const char* src, size_t n);
char* strcat(char* dest, const char* src);
char* strchr(const char* str, int c);
void* memset(void* ptr, int value, size_t num);
void* memcpy(void* dest, const void* src, size_t num);
int memcmp(const void* ptr1, const void* ptr2, size_t num);

// Additional utility functions
void str_to_upper(char* str);
void str_to_lower(char* str);
int str_starts_with(const char* str, const char* prefix);
char* str_trim(char* str);

#endif // STRING_H
