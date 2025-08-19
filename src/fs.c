#include "fs.h"
#include "string.h"
#include "memory.h"

// Maximum filesystem nodes
#define MAX_FS_NODES 64
#define MAX_DIR_ENTRIES 32

// Simple in-memory filesystem (ramdisk)
static fs_node_t fs_nodes[MAX_FS_NODES];
static dirent_t dir_entries[MAX_FS_NODES][MAX_DIR_ENTRIES];
static int fs_node_count = 0;
static fs_node_t* current_directory = NULL;

// Root filesystem node
fs_node_t fs_root;

// Sample file contents
static char readme_content[] = "Welcome to ScooterOS!\n\nThis is a simple operating system with:\n- GUI interface\n- Memory management\n- File system\n- Command line interface\n\nPress F to toggle CLI mode.\nUse 'help' for available commands.";
static char hello_content[] = "Hello, World!\nThis is a test file in the ScooterOS filesystem.\n\nYou can create, read, and delete files using the CLI.";
static char system_info[] = "ScooterOS v1.0\nBuild: Debug\nArch: x86-32\nMemory: Dynamic allocation\nFilesystem: In-memory ramdisk";

// Helper function to get next available inode
static uint32_t get_next_inode() {
    static uint32_t next_inode = 1;
    return next_inode++;
}

// Helper function to get current time (simplified)
static uint32_t get_current_time() {
    static uint32_t time_counter = 1000;
    return time_counter++;
}

// Read from a ramdisk file
static uint32_t read_ramdisk(fs_node_t* node, uint32_t offset, uint32_t size, uint8_t* buffer) {
    if (!node || !buffer || !(node->flags & FS_FILE)) {
        return 0;
    }
    
    if (offset >= node->length) {
        return 0;
    }
    
    if (offset + size > node->length) {
        size = node->length - offset;
    }
    
    if (node->ptr) {
        memcpy(buffer, (uint8_t*)node->ptr + offset, size);
        return size;
    }
    
    return 0;
}

// Write to a ramdisk file
static uint32_t write_ramdisk(fs_node_t* node, uint32_t offset, uint32_t size, uint8_t* buffer) {
    if (!node || !buffer || !(node->flags & FS_FILE)) {
        return 0;
    }
    
    // For simplicity, we don't support writing beyond current file size
    if (offset >= node->length) {
        return 0;
    }
    
    if (offset + size > node->length) {
        size = node->length - offset;
    }
    
    if (node->ptr) {
        memcpy((uint8_t*)node->ptr + offset, buffer, size);
        node->modified_time = get_current_time();
        return size;
    }
    
    return 0;
}

// Read directory entries
static dirent_t* readdir_ramdisk(fs_node_t* node, uint32_t index) {
    if (!node || !(node->flags & FS_DIRECTORY)) {
        return NULL;
    }
    
    // Count entries in this directory
    int entry_count = 0;
    for (int i = 0; i < MAX_DIR_ENTRIES; i++) {
        if (dir_entries[node->inode][i].name[0] != '\0') {
            if (entry_count == index) {
                return &dir_entries[node->inode][i];
            }
            entry_count++;
        }
    }
    
    return NULL;
}

// Find a file/directory by name
static fs_node_t* finddir_ramdisk(fs_node_t* node, char* name) {
    if (!node || !name || !(node->flags & FS_DIRECTORY)) {
        return NULL;
    }
    
    // Search through directory entries
    for (int i = 0; i < MAX_DIR_ENTRIES; i++) {
        if (dir_entries[node->inode][i].name[0] != '\0' && 
            strcmp(dir_entries[node->inode][i].name, name) == 0) {
            
            uint32_t target_inode = dir_entries[node->inode][i].inode;
            
            // Find the node with this inode
            for (int j = 0; j < fs_node_count; j++) {
                if (fs_nodes[j].inode == target_inode) {
                    return &fs_nodes[j];
                }
            }
        }
    }
    
    return NULL;
}

// Create a directory
static int mkdir_ramdisk(fs_node_t* parent, char* name) {
    if (!parent || !name || !(parent->flags & FS_DIRECTORY) || fs_node_count >= MAX_FS_NODES) {
        return -1;
    }
    
    // Check if name already exists
    if (finddir_ramdisk(parent, name)) {
        return -1; // Already exists
    }
    
    // Find empty slot in parent directory
    int dir_slot = -1;
    for (int i = 0; i < MAX_DIR_ENTRIES; i++) {
        if (dir_entries[parent->inode][i].name[0] == '\0') {
            dir_slot = i;
            break;
        }
    }
    
    if (dir_slot == -1) {
        return -1; // Directory full
    }
    
    // Create new directory node
    fs_node_t* new_dir = &fs_nodes[fs_node_count++];
    strcpy(new_dir->name, name);
    new_dir->flags = FS_DIRECTORY;
    new_dir->permissions = FS_PERM_READ | FS_PERM_WRITE | FS_PERM_EXEC;
    new_dir->length = 0;
    new_dir->inode = get_next_inode();
    new_dir->created_time = get_current_time();
    new_dir->modified_time = new_dir->created_time;
    new_dir->ptr = NULL;
    new_dir->parent = parent;
    
    // Add to parent directory
    strcpy(dir_entries[parent->inode][dir_slot].name, name);
    dir_entries[parent->inode][dir_slot].inode = new_dir->inode;
    dir_entries[parent->inode][dir_slot].type = FS_DIRECTORY;
    
    return 0;
}

// Create a file
static int create_ramdisk(fs_node_t* parent, char* name) {
    if (!parent || !name || !(parent->flags & FS_DIRECTORY) || fs_node_count >= MAX_FS_NODES) {
        return -1;
    }
    
    // Check if name already exists
    if (finddir_ramdisk(parent, name)) {
        return -1; // Already exists
    }
    
    // Find empty slot in parent directory
    int dir_slot = -1;
    for (int i = 0; i < MAX_DIR_ENTRIES; i++) {
        if (dir_entries[parent->inode][i].name[0] == '\0') {
            dir_slot = i;
            break;
        }
    }
    
    if (dir_slot == -1) {
        return -1; // Directory full
    }
    
    // Create new file node
    fs_node_t* new_file = &fs_nodes[fs_node_count++];
    strcpy(new_file->name, name);
    new_file->flags = FS_FILE;
    new_file->permissions = FS_PERM_READ | FS_PERM_WRITE;
    new_file->length = 0;
    new_file->inode = get_next_inode();
    new_file->created_time = get_current_time();
    new_file->modified_time = new_file->created_time;
    new_file->ptr = NULL;
    new_file->parent = parent;
    
    // Add to parent directory
    strcpy(dir_entries[parent->inode][dir_slot].name, name);
    dir_entries[parent->inode][dir_slot].inode = new_file->inode;
    dir_entries[parent->inode][dir_slot].type = FS_FILE;
    
    return 0;
}

// Helper function to create a file with content
static fs_node_t* create_file_with_content(fs_node_t* parent, char* name, char* content) {
    if (!parent || !name || !content) {
        return NULL;
    }
    
    if (create_ramdisk(parent, name) != 0) {
        return NULL;
    }
    
    fs_node_t* file = finddir_ramdisk(parent, name);
    if (file) {
        file->length = strlen(content);
        file->ptr = (struct fs_node*)content;
        
        // Set up VFS function pointers
        ((fs_node_vfs_t*)file)->read = &read_ramdisk;
        ((fs_node_vfs_t*)file)->write = &write_ramdisk;
    }
    
    return file;
}

// Initialize the filesystem
void fs_init() {
    // Clear all nodes and directory entries
    memset(fs_nodes, 0, sizeof(fs_nodes));
    memset(dir_entries, 0, sizeof(dir_entries));
    fs_node_count = 0;
    
    // Root directory
    fs_node_t* root = &fs_nodes[fs_node_count++];
    strcpy(root->name, "/");
    root->flags = FS_DIRECTORY;
    root->permissions = FS_PERM_READ | FS_PERM_WRITE | FS_PERM_EXEC;
    root->length = 0;
    root->inode = 0;
    root->created_time = get_current_time();
    root->modified_time = root->created_time;
    root->ptr = NULL;
    root->parent = NULL;
    
    // Set up VFS function pointers for root
    ((fs_node_vfs_t*)root)->readdir = &readdir_ramdisk;
    ((fs_node_vfs_t*)root)->finddir = &finddir_ramdisk;
    ((fs_node_vfs_t*)root)->mkdir = &mkdir_ramdisk;
    ((fs_node_vfs_t*)root)->create = &create_ramdisk;
    
    // Copy root to global
    fs_root = *root;
    current_directory = &fs_root;
    
    // Create some sample files and directories
    create_file_with_content(&fs_root, "readme.txt", readme_content);
    create_file_with_content(&fs_root, "hello.txt", hello_content);
    create_file_with_content(&fs_root, "system.info", system_info);
    
    // Create a documents directory
    mkdir_ramdisk(&fs_root, "documents");
    fs_node_t* docs_dir = finddir_ramdisk(&fs_root, "documents");
    if (docs_dir) {
        // Set up VFS function pointers for documents directory
        ((fs_node_vfs_t*)docs_dir)->readdir = &readdir_ramdisk;
        ((fs_node_vfs_t*)docs_dir)->finddir = &finddir_ramdisk;
        ((fs_node_vfs_t*)docs_dir)->mkdir = &mkdir_ramdisk;
        ((fs_node_vfs_t*)docs_dir)->create = &create_ramdisk;
        
        create_file_with_content(docs_dir, "notes.txt", "Personal notes file.\nYou can write your thoughts here.");
    }
    
    // Create a bin directory
    mkdir_ramdisk(&fs_root, "bin");
    fs_node_t* bin_dir = finddir_ramdisk(&fs_root, "bin");
    if (bin_dir) {
        ((fs_node_vfs_t*)bin_dir)->readdir = &readdir_ramdisk;
        ((fs_node_vfs_t*)bin_dir)->finddir = &finddir_ramdisk;
        ((fs_node_vfs_t*)bin_dir)->mkdir = &mkdir_ramdisk;
        ((fs_node_vfs_t*)bin_dir)->create = &create_ramdisk;
        
        create_file_with_content(bin_dir, "test.exe", "Mock executable file");
    }
}

// Find a file by relative path
fs_node_t* fs_find(char* path) {
    if (!path) {
        return NULL;
    }
    
    fs_node_t* current = current_directory;
    
    // Handle absolute paths
    if (path[0] == '/') {
        current = &fs_root;
        path++;
    }
    
    // Handle empty path or just "/"
    if (path[0] == '\0') {
        return current;
    }
    
    // Parse path components
    char path_copy[256];
    strcpy(path_copy, path);
    
    char* token = path_copy;
    char* next_token;
    
    while (token && *token) {
        // Find next path separator
        next_token = strchr(token, '/');
        if (next_token) {
            *next_token = '\0';
            next_token++;
        }
        
        // Handle special directories
        if (strcmp(token, ".") == 0) {
            // Current directory - no change
        } else if (strcmp(token, "..") == 0) {
            // Parent directory
            if (current->parent) {
                current = current->parent;
            }
        } else {
            // Find the named entry
            current = finddir_ramdisk(current, token);
            if (!current) {
                return NULL; // Path not found
            }
        }
        
        token = next_token;
    }
    
    return current;
}

// Find a file by absolute path
fs_node_t* fs_find_absolute(char* path) {
    if (!path || path[0] != '/') {
        return NULL;
    }
    
    fs_node_t* current = &fs_root;
    path++; // Skip leading '/'
    
    if (*path == '\0') {
        return current; // Root directory
    }
    
    char path_copy[256];
    strcpy(path_copy, path);
    
    char* token = path_copy;
    char* next_token;
    
    while (token && *token) {
        next_token = strchr(token, '/');
        if (next_token) {
            *next_token = '\0';
            next_token++;
        }
        
        current = finddir_ramdisk(current, token);
        if (!current) {
            return NULL;
        }
        
        token = next_token;
    }
    
    return current;
}

// Read from a file
uint32_t fs_read(fs_node_t* node, uint32_t offset, uint32_t size, uint8_t* buffer) {
    if (!node || ((fs_node_vfs_t*)node)->read == NULL) {
        return 0;
    }
    return ((fs_node_vfs_t*)node)->read(node, offset, size, buffer);
}

// Write to a file
uint32_t fs_write(fs_node_t* node, uint32_t offset, uint32_t size, uint8_t* buffer) {
    if (!node || ((fs_node_vfs_t*)node)->write == NULL) {
        return 0;
    }
    return ((fs_node_vfs_t*)node)->write(node, offset, size, buffer);
}

// Read a directory
dirent_t* fs_readdir(fs_node_t* node, uint32_t index) {
    if (!node || !(node->flags & FS_DIRECTORY) || ((fs_node_vfs_t*)node)->readdir == NULL) {
        return NULL;
    }
    return ((fs_node_vfs_t*)node)->readdir(node, index);
}

// Create a directory
int fs_mkdir(fs_node_t* parent, char* name) {
    if (!parent || !name || ((fs_node_vfs_t*)parent)->mkdir == NULL) {
        return -1;
    }
    return ((fs_node_vfs_t*)parent)->mkdir(parent, name);
}

// Create a file with content
int fs_create_file(fs_node_t* parent, char* name, char* content) {
    if (!parent || !name) {
        return -1;
    }
    
    if (create_ramdisk(parent, name) != 0) {
        return -1;
    }
    
    if (content) {
        fs_node_t* file = finddir_ramdisk(parent, name);
        if (file) {
            // Allocate memory for content
            char* file_content = (char*)malloc(strlen(content) + 1);
            if (file_content) {
                strcpy(file_content, content);
                file->length = strlen(content);
                file->ptr = (struct fs_node*)file_content;
                
                // Set up VFS function pointers
                ((fs_node_vfs_t*)file)->read = &read_ramdisk;
                ((fs_node_vfs_t*)file)->write = &write_ramdisk;
            }
        }
    }
    
    return 0;
}

// Get filesystem statistics
fs_stats_t fs_get_stats() {
    fs_stats_t stats = {0};
    
    for (int i = 0; i < fs_node_count; i++) {
        if (fs_nodes[i].flags & FS_FILE) {
            stats.total_files++;
            stats.total_size += fs_nodes[i].length;
        } else if (fs_nodes[i].flags & FS_DIRECTORY) {
            stats.total_directories++;
        }
    }
    
    stats.free_space = (MAX_FS_NODES - fs_node_count) * 1024; // Approximation
    
    return stats;
}

// Get current directory
fs_node_t* fs_get_current_directory() {
    return current_directory;
}

// Get the root directory
fs_node_t* get_root_directory() {
    return &fs_root;
}

// Set current directory
void fs_set_current_directory(fs_node_t* dir) {
    if (dir && (dir->flags & FS_DIRECTORY)) {
        current_directory = dir;
    }
}

// Get current path as string
char* fs_get_current_path() {
    static char path_buffer[512];
    path_buffer[0] = '\0';
    
    if (!current_directory) {
        strcpy(path_buffer, "/");
        return path_buffer;
    }
    
    // Build path by walking up the tree
    fs_node_t* nodes[32];
    int depth = 0;
    fs_node_t* current = current_directory;
    
    while (current && depth < 32) {
        nodes[depth++] = current;
        current = current->parent;
    }
    
    // Build path string
    if (depth == 1 && nodes[0] == &fs_root) {
        strcpy(path_buffer, "/");
    } else {
        for (int i = depth - 1; i >= 0; i--) {
            if (nodes[i] != &fs_root) {
                strcat(path_buffer, "/");
                strcat(path_buffer, nodes[i]->name);
            }
        }
        if (path_buffer[0] == '\0') {
            strcpy(path_buffer, "/");
        }
    }
    
    return path_buffer;
}

// Get file type as string
char* fs_get_file_type_string(fs_node_t* node) {
    if (!node) return "unknown";
    
    if (node->flags & FS_DIRECTORY) return "directory";
    if (node->flags & FS_FILE) return "file";
    if (node->flags & FS_CHARDEVICE) return "char device";
    if (node->flags & FS_BLOCKDEVICE) return "block device";
    if (node->flags & FS_PIPE) return "pipe";
    if (node->flags & FS_SYMLINK) return "symlink";
    
    return "unknown";
}

// Check if filename is valid
int fs_is_valid_filename(char* name) {
    if (!name || strlen(name) == 0 || strlen(name) > 127) {
        return 0;
    }
    
    // Check for invalid characters
    char* invalid_chars = "\\/:*?\"<>|";
    for (int i = 0; i < strlen(name); i++) {
        if (strchr(invalid_chars, name[i])) {
            return 0;
        }
    }
    
    // Check for reserved names
    if (strcmp(name, ".") == 0 || strcmp(name, "..") == 0) {
        return 0;
    }
    
    return 1;
}
