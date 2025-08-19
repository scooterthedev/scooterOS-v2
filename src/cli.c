#include "cli.h"
#include "fs.h"
#include "gui.h"
#include "string.h"
#include "memory.h"

// CLI state
cli_state_t cli;
static int cli_scroll_offset = 0;
static char output_buffer[4096];
static int output_pos = 0;

// CLI dimensions
#define CLI_X 10
#define CLI_Y 10
#define CLI_WIDTH 300
#define CLI_HEIGHT 180
#define CLI_TEXT_ROWS 20
#define CLI_TEXT_COLS 35

// Command table
static cli_command_t commands[] = {
    {"help", "Show available commands", cmd_help},
    {"ls", "List directory contents", cmd_ls},
    {"cat", "Display file contents", cmd_cat},
    {"cd", "Change directory", cmd_cd},
    {"pwd", "Print working directory", cmd_pwd},
    {"mkdir", "Create directory", cmd_mkdir},
    {"touch", "Create empty file", cmd_touch},
    {"echo", "Display text", cmd_echo},
    {"clear", "Clear screen", cmd_clear},
    {"tree", "Show directory tree", cmd_tree},
    {"stat", "Show file/directory info", cmd_stat},
    {"mem", "Show memory information", cmd_mem},
    {"exit", "Exit CLI mode", cmd_exit},
    {"", "", NULL} // Terminator
};

void cli_init() {
    memset(&cli, 0, sizeof(cli));
    cli.cursor_x = 20;
    cli.cursor_y = 40;
    cli.active = 0;
    output_pos = 0;
    memset(output_buffer, 0, sizeof(output_buffer));
    strcpy(cli.current_path, "/");
}

void cli_clear_screen() {
    output_pos = 0;
    memset(output_buffer, 0, sizeof(output_buffer));
    cli_scroll_offset = 0;
}

void cli_print(char* text) {
    if (!text) return;
    
    int len = strlen(text);
    if (output_pos + len < sizeof(output_buffer) - 1) {
        strcpy(output_buffer + output_pos, text);
        output_pos += len;
    }
}

void cli_println(char* text) {
    cli_print(text);
    cli_print("\n");
}

void cli_print_error(char* message) {
    cli_print("Error: ");
    cli_println(message);
}

void cli_print_success(char* message) {
    cli_println(message);
}

void cli_prompt() {
    cli_print(cli.current_path);
    cli_print("$ ");
}

void cli_draw() {
    // Draw CLI window background
    draw_filled_rectangle(CLI_X, CLI_Y, CLI_WIDTH, CLI_HEIGHT, COLOR_BLACK);
    draw_rectangle(CLI_X, CLI_Y, CLI_WIDTH, CLI_HEIGHT, COLOR_WHITE);
    
    // Draw title bar
    draw_filled_rectangle(CLI_X + 1, CLI_Y + 1, CLI_WIDTH - 2, 15, COLOR_DARK_GRAY);
    draw_text(CLI_X + 5, CLI_Y + 5, "ScooterOS Command Line Interface", COLOR_WHITE);
    
    // Draw output text
    int y = CLI_Y + 20;
    int line_height = 9;
    int max_lines = (CLI_HEIGHT - 40) / line_height;
    
    // Parse output buffer into lines
    char* line_start = output_buffer;
    char* current = output_buffer;
    int line_count = 0;
    
    while (*current && line_count < max_lines) {
        if (*current == '\n' || (current - line_start) >= CLI_TEXT_COLS) {
            // Draw this line
            char line_buffer[CLI_TEXT_COLS + 1];
            int line_len = current - line_start;
            if (line_len > CLI_TEXT_COLS) line_len = CLI_TEXT_COLS;
            
            strncpy(line_buffer, line_start, line_len);
            line_buffer[line_len] = '\0';
            
            draw_text(CLI_X + 5, y + line_count * line_height, line_buffer, COLOR_WHITE);
            
            if (*current == '\n') {
                current++;
            }
            line_start = current;
            line_count++;
        } else {
            current++;
        }
    }
    
    // Draw current command line
    int prompt_y = CLI_Y + CLI_HEIGHT - 25;
    draw_text(CLI_X + 5, prompt_y, cli.current_path, COLOR_YELLOW);
    
    char prompt_buffer[256];
    strcpy(prompt_buffer, cli.current_path);
    strcat(prompt_buffer, "$ ");
    strcat(prompt_buffer, cli.buffer);
    
    int prompt_len = strlen(cli.current_path) + 2;
    draw_text(CLI_X + 5, prompt_y + 10, prompt_buffer, COLOR_WHITE);
    
    // Draw cursor
    int cursor_x = CLI_X + 5 + (prompt_len + cli.buffer_pos) * 8;
    draw_filled_rectangle(cursor_x, prompt_y + 10, 8, 8, COLOR_WHITE);
}

void cli_toggle() {
    cli.active = !cli.active;
    if (cli.active) {
        cli_clear_screen();
        cli_println("ScooterOS Command Line Interface v1.0");
        cli_println("Type 'help' for available commands.");
        cli_println("");
    }
}

void cli_parse_command(char* input, char* argv[], int* argc) {
    *argc = 0;
    char* token = input;
    
    while (*token && *argc < CLI_MAX_ARGS - 1) {
        // Skip leading spaces
        while (*token == ' ') token++;
        if (*token == '\0') break;
        
        argv[*argc] = token;
        (*argc)++;
        
        // Find end of token
        while (*token && *token != ' ') token++;
        if (*token) {
            *token = '\0';
            token++;
        }
    }
    argv[*argc] = NULL;
}

cli_command_t* cli_find_command(char* name) {
    for (int i = 0; commands[i].handler != NULL; i++) {
        if (strcmp(commands[i].name, name) == 0) {
            return &commands[i];
        }
    }
    return NULL;
}

void cli_handle_input(char* input) {
    if (!input || strlen(input) == 0) {
        return;
    }
    
    // Add to history
    if (cli.history_count < CLI_HISTORY_SIZE) {
        strcpy(cli.history[cli.history_count], input);
        cli.history_count++;
    }
    
    // Parse command
    char* argv[CLI_MAX_ARGS];
    int argc;
    cli_parse_command(input, argv, &argc);
    
    if (argc == 0) return;
    
    // Find and execute command
    cli_command_t* cmd = cli_find_command(argv[0]);
    if (cmd) {
        cmd->handler(argc, argv);
    } else {
        cli_print("Unknown command: ");
        cli_print(argv[0]);
        cli_println(". Type 'help' for available commands.");
    }
    
    cli_println("");
}

void cli_handle_keypress(unsigned char key) {
    if (!cli.active) return;
    
    switch (key) {
        case 0x1C: // Enter
            if (cli.buffer_pos > 0) {
                cli.buffer[cli.buffer_pos] = '\0';
                cli_print(cli.current_path);
                cli_print("$ ");
                cli_println(cli.buffer);
                
                cli_handle_input(cli.buffer);
                
                // Clear buffer
                memset(cli.buffer, 0, sizeof(cli.buffer));
                cli.buffer_pos = 0;
            }
            break;
            
        case 0x0E: // Backspace
            if (cli.buffer_pos > 0) {
                cli.buffer_pos--;
                cli.buffer[cli.buffer_pos] = '\0';
            }
            break;
            
        case 0x39: // Space
            if (cli.buffer_pos < CLI_BUFFER_SIZE - 1) {
                cli.buffer[cli.buffer_pos++] = ' ';
            }
            break;
            
        default:
            // Handle regular characters
            if (key >= 0x10 && key <= 0x32 && cli.buffer_pos < CLI_BUFFER_SIZE - 1) {
                // Convert scan code to ASCII (simplified)
                char c = '?';
                switch (key) {
                    case 0x10: c = 'q'; break;
                    case 0x11: c = 'w'; break;
                    case 0x12: c = 'e'; break;
                    case 0x13: c = 'r'; break;
                    case 0x14: c = 't'; break;
                    case 0x15: c = 'y'; break;
                    case 0x16: c = 'u'; break;
                    case 0x17: c = 'i'; break;
                    case 0x18: c = 'o'; break;
                    case 0x19: c = 'p'; break;
                    case 0x1E: c = 'a'; break;
                    case 0x1F: c = 's'; break;
                    case 0x20: c = 'd'; break;
                    case 0x21: c = 'f'; break;
                    case 0x22: c = 'g'; break;
                    case 0x23: c = 'h'; break;
                    case 0x24: c = 'j'; break;
                    case 0x25: c = 'k'; break;
                    case 0x26: c = 'l'; break;
                    case 0x2C: c = 'z'; break;
                    case 0x2D: c = 'x'; break;
                    case 0x2E: c = 'c'; break;
                    case 0x2F: c = 'v'; break;
                    case 0x30: c = 'b'; break;
                    case 0x31: c = 'n'; break;
                    case 0x32: c = 'm'; break;
                    case 0x02: c = '1'; break;
                    case 0x03: c = '2'; break;
                    case 0x04: c = '3'; break;
                    case 0x05: c = '4'; break;
                    case 0x06: c = '5'; break;
                    case 0x07: c = '6'; break;
                    case 0x08: c = '7'; break;
                    case 0x09: c = '8'; break;
                    case 0x0A: c = '9'; break;
                    case 0x0B: c = '0'; break;
                    case 0x34: c = '.'; break;
                    case 0x35: c = '/'; break;
                }
                
                if (c != '?') {
                    cli.buffer[cli.buffer_pos++] = c;
                }
            }
            break;
    }
}

void cli_run() {
    if (!cli.active) return;
    cli_draw();
}

// Command implementations
int cmd_help(int argc, char* argv[]) {
    cli_println("Available commands:");
    cli_println("==================");
    
    for (int i = 0; commands[i].handler != NULL; i++) {
        char line[256];
        strcpy(line, commands[i].name);
        
        // Pad with spaces
        int len = strlen(line);
        while (len < 12) {
            strcat(line, " ");
            len++;
        }
        
        strcat(line, "- ");
        strcat(line, commands[i].description);
        cli_println(line);
    }
    
    return 0;
}

int cmd_ls(int argc, char* argv[]) {
    fs_node_t* dir = fs_get_current_directory();
    if (!dir) {
        cli_print_error("Cannot access current directory");
        return -1;
    }
    
    if (argc > 1) {
        dir = fs_find(argv[1]);
        if (!dir) {
            cli_print_error("Directory not found");
            return -1;
        }
    }
    
    if (!(dir->flags & FS_DIRECTORY)) {
        cli_print_error("Not a directory");
        return -1;
    }
    
    cli_print("Contents of ");
    cli_print(dir->name);
    cli_println(":");
    
    dirent_t* entry;
    int index = 0;
    while ((entry = fs_readdir(dir, index++))) {
        char line[256];
        
        // Find the actual node to get type info
        fs_node_t* node = fs_find(entry->name);
        if (node) {
            if (node->flags & FS_DIRECTORY) {
                strcpy(line, "[DIR]  ");
            } else {
                strcpy(line, "[FILE] ");
            }
            strcat(line, entry->name);
            
            if (node->flags & FS_FILE) {
                char size_str[32];
                // Simple integer to string conversion
                int size = node->length;
                if (size == 0) {
                    strcat(line, " (0 bytes)");
                } else {
                    strcat(line, " (");
                    // Convert size to string manually
                    char temp[16];
                    int pos = 0;
                    while (size > 0) {
                        temp[pos++] = '0' + (size % 10);
                        size /= 10;
                    }
                    for (int i = pos - 1; i >= 0; i--) {
                        char c[2] = {temp[i], '\0'};
                        strcat(line, c);
                    }
                    strcat(line, " bytes)");
                }
            }
        } else {
            strcpy(line, "[???]  ");
            strcat(line, entry->name);
        }
        
        cli_println(line);
    }
    
    return 0;
}

int cmd_cat(int argc, char* argv[]) {
    if (argc < 2) {
        cli_print_error("Usage: cat <filename>");
        return -1;
    }
    
    fs_node_t* file = fs_find(argv[1]);
    if (!file) {
        cli_print_error("File not found");
        return -1;
    }
    
    if (!(file->flags & FS_FILE)) {
        cli_print_error("Not a file");
        return -1;
    }
    
    char content[512];
    uint32_t bytes_read = fs_read(file, 0, sizeof(content) - 1, (uint8_t*)content);
    content[bytes_read] = '\0';
    
    cli_println(content);
    
    return 0;
}

int cmd_cd(int argc, char* argv[]) {
    fs_node_t* target_dir;
    
    if (argc < 2) {
        // Go to root directory
        target_dir = get_root_directory();
    } else {
        target_dir = fs_find(argv[1]);
        if (!target_dir) {
            cli_print_error("Directory not found");
            return -1;
        }
        
        if (!(target_dir->flags & FS_DIRECTORY)) {
            cli_print_error("Not a directory");
            return -1;
        }
    }
    
    fs_set_current_directory(target_dir);
    strcpy(cli.current_path, fs_get_current_path());
    
    return 0;
}

int cmd_pwd(int argc, char* argv[]) {
    cli_println(fs_get_current_path());
    return 0;
}

int cmd_mkdir(int argc, char* argv[]) {
    if (argc < 2) {
        cli_print_error("Usage: mkdir <directory_name>");
        return -1;
    }
    
    if (!fs_is_valid_filename(argv[1])) {
        cli_print_error("Invalid directory name");
        return -1;
    }
    
    fs_node_t* current_dir = fs_get_current_directory();
    if (fs_mkdir(current_dir, argv[1]) == 0) {
        cli_print_success("Directory created");
    } else {
        cli_print_error("Failed to create directory");
    }
    
    return 0;
}

int cmd_touch(int argc, char* argv[]) {
    if (argc < 2) {
        cli_print_error("Usage: touch <filename>");
        return -1;
    }
    
    if (!fs_is_valid_filename(argv[1])) {
        cli_print_error("Invalid filename");
        return -1;
    }
    
    fs_node_t* current_dir = fs_get_current_directory();
    if (fs_create_file(current_dir, argv[1], "") == 0) {
        cli_print_success("File created");
    } else {
        cli_print_error("Failed to create file");
    }
    
    return 0;
}

int cmd_echo(int argc, char* argv[]) {
    for (int i = 1; i < argc; i++) {
        cli_print(argv[i]);
        if (i < argc - 1) {
            cli_print(" ");
        }
    }
    cli_println("");
    
    return 0;
}

int cmd_clear(int argc, char* argv[]) {
    cli_clear_screen();
    return 0;
}

int cmd_tree(int argc, char* argv[]) {
    cli_println("Directory tree structure:");
    cli_println("========================");
    // TODO: Implement tree traversal
    cli_println("/ (root)");
    cli_println("├── readme.txt");
    cli_println("├── hello.txt");
    cli_println("├── system.info");
    cli_println("├── documents/");
    cli_println("│   └── notes.txt");
    cli_println("└── bin/");
    cli_println("    └── test.exe");
    
    return 0;
}

int cmd_stat(int argc, char* argv[]) {
    if (argc < 2) {
        cli_print_error("Usage: stat <filename>");
        return -1;
    }
    
    fs_node_t* node = fs_find(argv[1]);
    if (!node) {
        cli_print_error("File not found");
        return -1;
    }
    
    cli_print("Name: ");
    cli_println(node->name);
    
    cli_print("Type: ");
    cli_println(fs_get_file_type_string(node));
    
    if (node->flags & FS_FILE) {
        cli_print("Size: ");
        // Convert size to string
        char size_str[32];
        int size = node->length;
        int pos = 0;
        if (size == 0) {
            size_str[pos++] = '0';
        } else {
            char temp[16];
            int temp_pos = 0;
            while (size > 0) {
                temp[temp_pos++] = '0' + (size % 10);
                size /= 10;
            }
            for (int i = temp_pos - 1; i >= 0; i--) {
                size_str[pos++] = temp[i];
            }
        }
        size_str[pos] = '\0';
        cli_print(size_str);
        cli_println(" bytes");
    }
    
    return 0;
}

int cmd_mem(int argc, char* argv[]) {
    memory_stats_t stats = get_memory_stats();
    
    cli_println("Memory Information:");
    cli_println("==================");
    
    // Convert numbers to strings and display
    char buffer[64];
    
    // Total allocated
    cli_print("Total allocated: ");
    int size = stats.total_allocated;
    int pos = 0;
    if (size == 0) {
        buffer[pos++] = '0';
    } else {
        char temp[16];
        int temp_pos = 0;
        while (size > 0) {
            temp[temp_pos++] = '0' + (size % 10);
            size /= 10;
        }
        for (int i = temp_pos - 1; i >= 0; i--) {
            buffer[pos++] = temp[i];
        }
    }
    buffer[pos] = '\0';
    cli_print(buffer);
    cli_println(" bytes");
    
    // Allocation count
    cli_print("Allocations: ");
    size = stats.allocation_count;
    pos = 0;
    if (size == 0) {
        buffer[pos++] = '0';
    } else {
        char temp[16];
        int temp_pos = 0;
        while (size > 0) {
            temp[temp_pos++] = '0' + (size % 10);
            size /= 10;
        }
        for (int i = temp_pos - 1; i >= 0; i--) {
            buffer[pos++] = temp[i];
        }
    }
    buffer[pos] = '\0';
    cli_println(buffer);
    
    return 0;
}

int cmd_exit(int argc, char* argv[]) {
    cli_toggle();
    return 0;
}
