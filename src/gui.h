#ifndef GUI_H
#define GUI_H

// Assembly function prototypes
extern void asm_clear_screen(unsigned char color);
extern void asm_draw_pixel(int x, int y, unsigned char color);
extern unsigned char asm_get_keyboard(void);
extern void asm_delay(unsigned int count);

// VGA Color constants
#define COLOR_BLACK     0x00
#define COLOR_BLUE      0x01
#define COLOR_GREEN     0x02
#define COLOR_CYAN      0x03
#define COLOR_RED       0x04
#define COLOR_MAGENTA   0x05
#define COLOR_BROWN     0x06
#define COLOR_WHITE     0x07
#define COLOR_GRAY      0x08
#define COLOR_LBLUE     0x09
#define COLOR_LGREEN    0x0A
#define COLOR_LCYAN     0x0B
#define COLOR_LRED      0x0C
#define COLOR_LMAGENTA  0x0D
#define COLOR_YELLOW    0x0E
#define COLOR_LWHITE    0x0F
#define COLOR_DARK_GRAY 0x08

// Screen dimensions
#define SCREEN_WIDTH    320
#define SCREEN_HEIGHT   200

// GUI function prototypes
void init_gui_system(void);
void show_loading_screen(void);
void show_desktop(void);
void display_memory_info(int x, int y);
void draw_text(int x, int y, const char* text, unsigned char color);
void draw_filled_rectangle(int x, int y, int width, int height, unsigned char color);
void draw_rectangle(int x, int y, int width, int height, unsigned char color);
void handle_keyboard_input(unsigned char key);

#endif
