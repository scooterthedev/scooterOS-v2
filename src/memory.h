#ifndef MEMORY_H
#define MEMORY_H

#include <stdint.h>

// Memory statistics structure
typedef struct {
    uint32_t total_allocated;
    uint32_t allocation_count;
    uint32_t free_count;
    uint32_t peak_usage;
} memory_stats_t;

// Memory management functions
void init_memory_manager(void);
void* malloc(uint32_t size);
void free(void* ptr);
memory_stats_t get_memory_stats(void);
void test_memory_system(void);

#endif
