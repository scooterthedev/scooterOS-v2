#ifndef FS_H
#define FS_H

#include <stddef.h>
#include <stdint.h>

struct fs_node;

// Filesystem node flags
#define FS_FILE        0x01
#define FS_DIRECTORY   0x02
#define FS_CHARDEVICE  0x03
#define FS_BLOCKDEVICE 0x04
#define FS_PIPE        0x05
#define FS_SYMLINK     0x06
#define FS_MOUNTPOINT  0x08

// File permissions
#define FS_PERM_READ   0x01
#define FS_PERM_WRITE  0x02
#define FS_PERM_EXEC   0x04

// Filesystem node structure
typedef struct fs_node {
    char name[128];
    uint32_t flags;
    uint32_t permissions;
    uint32_t length;
    uint32_t inode;
    uint32_t created_time;
    uint32_t modified_time;
    struct fs_node *ptr; // Used by ramdisk for content pointer
    struct fs_node *parent; // Parent directory
} fs_node_t;

// Directory entry structure
typedef struct dirent {
    char name[128];
    uint32_t inode;
    uint8_t type;
} dirent_t;

// File system statistics
typedef struct fs_stats {
    uint32_t total_files;
    uint32_t total_directories;
    uint32_t total_size;
    uint32_t free_space;
} fs_stats_t;

// Function pointers for VFS
typedef uint32_t (*read_type_t)(fs_node_t*, uint32_t, uint32_t, uint8_t*);
typedef uint32_t (*write_type_t)(fs_node_t*, uint32_t, uint32_t, uint8_t*);
typedef void (*open_type_t)(fs_node_t*);
typedef void (*close_type_t)(fs_node_t*);
typedef dirent_t* (*readdir_type_t)(fs_node_t*, uint32_t);
typedef fs_node_t* (*finddir_type_t)(fs_node_t*, char *name);
typedef int (*mkdir_type_t)(fs_node_t*, char *name);
typedef int (*rmdir_type_t)(fs_node_t*, char *name);
typedef int (*create_type_t)(fs_node_t*, char *name);
typedef int (*unlink_type_t)(fs_node_t*, char *name);

// Add function pointers to fs_node
typedef struct fs_node_vfs {
    fs_node_t node;
    read_type_t read;
    write_type_t write;
    open_type_t open;
    close_type_t close;
    readdir_type_t readdir;
    finddir_type_t finddir;
    mkdir_type_t mkdir;
    rmdir_type_t rmdir;
    create_type_t create;
    unlink_type_t unlink;
} fs_node_vfs_t;

// Public functions
void fs_init();
fs_node_t* get_root_directory();
fs_node_t* fs_find(char* path);
fs_node_t* fs_find_absolute(char* path);
uint32_t fs_read(fs_node_t* node, uint32_t offset, uint32_t size, uint8_t* buffer);
uint32_t fs_write(fs_node_t* node, uint32_t offset, uint32_t size, uint8_t* buffer);
dirent_t* fs_readdir(fs_node_t* node, uint32_t index);
int fs_mkdir(fs_node_t* parent, char* name);
int fs_create_file(fs_node_t* parent, char* name, char* content);
int fs_delete(fs_node_t* parent, char* name);
fs_stats_t fs_get_stats();
char* fs_get_current_path();
void fs_set_current_directory(fs_node_t* dir);
fs_node_t* fs_get_current_directory();

// Utility functions
void fs_print_tree(fs_node_t* node, int depth);
int fs_is_valid_filename(char* name);
char* fs_get_file_type_string(fs_node_t* node);

#endif // FS_H
