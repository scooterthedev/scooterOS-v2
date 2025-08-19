#ifndef CLI_H
#define CLI_H

#include "fs.h"

// CLI constants
#define CLI_BUFFER_SIZE 256
#define CLI_HISTORY_SIZE 10
#define CLI_MAX_ARGS 16

// CLI state structure
typedef struct {
    char buffer[CLI_BUFFER_SIZE];
    int buffer_pos;
    int cursor_x, cursor_y;
    int active;
    char history[CLI_HISTORY_SIZE][CLI_BUFFER_SIZE];
    int history_count;
    int history_index;
    char current_path[256];
} cli_state_t;

// Command structure
typedef struct {
    char name[32];
    char description[128];
    int (*handler)(int argc, char* argv[]);
} cli_command_t;

// CLI functions
void cli_init();
void cli_run();
void cli_toggle();
void cli_handle_input(char* input);
void cli_handle_keypress(unsigned char key);
void cli_draw();
void cli_clear_screen();
void cli_print(char* text);
void cli_println(char* text);
void cli_prompt();

// Global CLI state (extern declaration)
extern cli_state_t cli;

// Command handlers
int cmd_help(int argc, char* argv[]);
int cmd_ls(int argc, char* argv[]);
int cmd_cat(int argc, char* argv[]);
int cmd_cd(int argc, char* argv[]);
int cmd_pwd(int argc, char* argv[]);
int cmd_mkdir(int argc, char* argv[]);
int cmd_touch(int argc, char* argv[]);
int cmd_echo(int argc, char* argv[]);
int cmd_clear(int argc, char* argv[]);
int cmd_tree(int argc, char* argv[]);
int cmd_stat(int argc, char* argv[]);
int cmd_mem(int argc, char* argv[]);
int cmd_exit(int argc, char* argv[]);

// Utility functions
void cli_parse_command(char* input, char* argv[], int* argc);
cli_command_t* cli_find_command(char* name);
void cli_print_error(char* message);
void cli_print_success(char* message);

#endif // CLI_H
