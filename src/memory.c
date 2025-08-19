#include "memory.h"

// Simple memory pool for demonstration
static char memory_pool[1024 * 1024]; // 1MB pool
static int pool_offset = 0;
static memory_stats_t stats = {0, 0, 0, 0};

void init_memory_manager(void) {
    pool_offset = 0;
    stats.total_allocated = 0;
    stats.allocation_count = 0;
    stats.free_count = 0;
    stats.peak_usage = 0;
}

void* malloc(uint32_t size) {
    if (pool_offset + size >= sizeof(memory_pool)) {
        return 0; // Out of memory
    }
    
    void* ptr = &memory_pool[pool_offset];
    pool_offset += size;
    stats.total_allocated += size;
    stats.allocation_count++;
    
    if (stats.total_allocated > stats.peak_usage) {
        stats.peak_usage = stats.total_allocated;
    }
    
    return ptr;
}

void free(void* ptr) {
    // Simple implementation - just update stats
    (void)ptr; // Suppress unused parameter warning
    stats.free_count++;
}

memory_stats_t get_memory_stats(void) {
    return stats;
}

void test_memory_system(void) {
    // Test memory allocation
    void* test_ptr = malloc(100);
    if (test_ptr) {
        free(test_ptr);
    }
}
