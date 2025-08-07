// Simple C kernel that uses the text driver
#include "text_driver.c"

// External function to call from assembly
void kernel_main(void) {
    // Show loading screen FIRST - before anything else
    show_loading_screen();
    
    // After loading, show the main GUI
    clear_screen(COLOR_GREEN);
    
    // Draw some test rectangles
    draw_rectangle(50, 50, 100, 80, 0x04);  // Red rectangle
    draw_rectangle(170, 70, 80, 60, 0x01);  // Blue rectangle
    
    // Draw GUI messages
    draw_string(60, 160, "GUI OS v1.0", COLOR_WHITE, 1);
    draw_string(60, 175, "Press ESC to exit", 0x0E, 1);
}
