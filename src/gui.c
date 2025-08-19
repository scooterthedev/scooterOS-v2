#include "gui.h"
#include "string.h"

// Simple font data (8x8 pixels per character, simplified)
static const unsigned char font_data[256][8] = {
    // Space (32)
    [32] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
    // A (65)
    [65] = {0x18, 0x24, 0x42, 0x7E, 0x42, 0x42, 0x42, 0x00},
    // Add more characters as needed...
    // For now, we'll use a simple pattern for all printable characters
};

void init_gui_system(void) {
    // Initialize GUI system
    asm_clear_screen(COLOR_BLUE);
}

void show_loading_screen(void) {
    asm_clear_screen(COLOR_BLACK);
    draw_text(100, 90, "Loading ScooterOS...", COLOR_WHITE);
    asm_delay(100000);
}

void show_desktop(void) {
    asm_clear_screen(COLOR_BLUE);
    draw_text(10, 10, "ScooterOS Desktop", COLOR_WHITE);
    draw_text(10, 25, "Press F or SPACE for CLI", COLOR_YELLOW);
}

void display_memory_info(int x, int y) {
    draw_text(x, y, "Memory: 16MB", COLOR_WHITE);
}

void draw_text(int x, int y, const char* text, unsigned char color) {
    int len = strlen(text);
    for (int i = 0; i < len; i++) {
        unsigned char ch = text[i];
        // Simple character rendering - just a basic block for each character
        for (int cy = 0; cy < 8; cy++) {
            for (int cx = 0; cx < 8; cx++) {
                // Simple pattern for demonstration
                if ((ch >= 32 && ch <= 126) && (cx == 1 || cy == 1 || cx == 6 || cy == 6)) {
                    asm_draw_pixel(x + i * 8 + cx, y + cy, color);
                }
            }
        }
    }
}

void draw_filled_rectangle(int x, int y, int width, int height, unsigned char color) {
    for (int dy = 0; dy < height; dy++) {
        for (int dx = 0; dx < width; dx++) {
            asm_draw_pixel(x + dx, y + dy, color);
        }
    }
}

void draw_rectangle(int x, int y, int width, int height, unsigned char color) {
    // Top and bottom lines
    for (int dx = 0; dx < width; dx++) {
        asm_draw_pixel(x + dx, y, color);
        asm_draw_pixel(x + dx, y + height - 1, color);
    }
    // Left and right lines
    for (int dy = 0; dy < height; dy++) {
        asm_draw_pixel(x, y + dy, color);
        asm_draw_pixel(x + width - 1, y + dy, color);
    }
}

void handle_keyboard_input(unsigned char key) {
    // Handle keyboard input - placeholder
    (void)key; // Suppress unused parameter warning
}
