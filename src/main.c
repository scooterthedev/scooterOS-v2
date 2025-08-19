#include "gui.h"
#include "memory.h"
#include "fs.h"
#include "cli.h"

// Assembly function declarations
extern void asm_clear_screen(unsigned char color);
extern void asm_draw_pixel(int x, int y, unsigned char color);
extern unsigned char asm_get_keyboard(void);
extern void asm_delay(unsigned int count);

// External CLI state
extern cli_state_t cli;

// Override the GUI functions to use assembly implementations
void clear_screen(unsigned char color) {
    asm_clear_screen(color);
}

void draw_pixel(int x, int y, unsigned char color) {
    asm_draw_pixel(x, y, color);
}

// Main C function called from assembly
void c_main(void) {
    // Initialize subsystems
    init_memory_manager();
    init_gui_system();
    fs_init();
    cli_init();
    
    // Show loading screen
    show_loading_screen();
    
    // Show desktop
    show_desktop();
    
    // Display memory information
    display_memory_info(200, 20);
    
    // Main event loop
    unsigned char last_key = 0;
    
    while (1) {
        unsigned char key = asm_get_keyboard();
        
        // Only process key press events (ignore release)
        if (key != last_key && !(key & 0x80)) {
            // Debug: Show scan code on screen (remove later)
            if (key != 0) {
                char debug_msg[32];
                debug_msg[0] = 'K';
                debug_msg[1] = 'e';
                debug_msg[2] = 'y';
                debug_msg[3] = ':';
                debug_msg[4] = ' ';
                debug_msg[5] = '0';
                debug_msg[6] = 'x';
                
                // Convert scan code to hex
                unsigned char high = (key >> 4) & 0x0F;
                unsigned char low = key & 0x0F;
                debug_msg[7] = (high < 10) ? ('0' + high) : ('A' + high - 10);
                debug_msg[8] = (low < 10) ? ('0' + low) : ('A' + low - 10);
                debug_msg[9] = '\0';
                
                draw_text(200, 100, debug_msg, COLOR_YELLOW);
            }
            
            // Try multiple possible scan codes for F key
            if (key == 0x21 || key == 0x3D || key == 0x42) { // F key variations
                cli_toggle();
                if (cli.active) {
                    // CLI mode activated - clear the debug message
                    draw_filled_rectangle(200, 100, 100, 10, COLOR_CYAN);
                } else {
                    // Returned to desktop mode
                    show_desktop();
                    display_memory_info(200, 20);
                }
            } else if (key == 0x39 && !cli.active) { // Spacebar as alternative CLI toggle
                cli_toggle();
                if (cli.active) {
                    // CLI mode activated - clear the debug message
                    draw_filled_rectangle(200, 100, 100, 10, COLOR_CYAN);
                }
            } else if (cli.active) {
                // Handle CLI input
                cli_handle_keypress(key);
            } else {
                switch (key) {
                    case 0x0F: // Tab
                        handle_keyboard_input(key);
                        break;
                        
                    case 0x1C: // Enter
                        handle_keyboard_input(key);
                        break;
                        
                    case 0x01: // ESC - reboot
                        // Simple reboot
                        asm volatile("mov $0xFE, %al; out %al, $0x64");
                        break;
                        
                    case 0x32: // M key - test memory
                        test_memory_system();
                        show_desktop(); // Refresh display
                        display_memory_info(200, 20);
                        break;
                }
            }
        }
        
        last_key = key;
        
        // Update display based on mode
        if (cli.active) {
            cli_run();
        }
        
        // Small delay to prevent excessive CPU usage
        asm_delay(0x10000);
    }
}
