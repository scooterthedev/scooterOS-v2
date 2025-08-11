# ScooterOS Technical Documentation

## Overview
ScooterOS is a 32-bit x86 operating system kernel written in NASM assembly language. It features a custom GUI, memory management, process management, and various system services.

## Architecture

### Boot Process
1. **Bootloader** (`boot.asm`): 16-bit real mode bootloader
   - Loads kernel from disk
   - Sets up initial memory layout
   - Switches to 32-bit protected mode
   - Transfers control to kernel

2. **Kernel Entry** (`kernel.asm`): 32-bit protected mode kernel
   - Sets up stack at 0x90000
   - Initializes system components
   - Displays loading screen
   - Starts GUI interface

### Memory Layout
```
0x00000000 - 0x000003FF    Interrupt Vector Table (IVT)
0x00000400 - 0x000004FF    BIOS Data Area
0x00000500 - 0x00007BFF    Conventional Memory (Available)
0x00007C00 - 0x00007DFF    Bootloader Location
0x00008000 - 0x0008FFFF    Stack and Kernel Data
0x00090000 - 0x0009FFFF    Stack Area (64KB)
0x000A0000 - 0x000BFFFF    VGA Graphics Memory
0x000C0000 - 0x000FFFFF    BIOS ROM Area
0x00100000 - 0x001FFFFF    Heap Area (1MB)
```

### System Components

## 1. Graphics System

### VGA Mode
- **Resolution**: 320x200 pixels
- **Color Depth**: 8-bit (256 colors)
- **Memory Address**: 0xA0000
- **Memory Size**: 64,000 bytes (320 × 200)

### Text Rendering
- **Font System**: Custom 8x8 bitmap fonts
- **Character Set**: ASCII 0x20-0x5A (Space to Z)
- **Font Data**: Each character uses 8 bytes (8x8 pixel matrix)
- **Anti-aliasing**: None (pixel-perfect rendering)

### Drawing Functions
```assembly
draw_single_pixel(x, y, color)     ; Draw single pixel
draw_filled_rectangle(x, y, w, h, color)  ; Draw rectangle
draw_text(x, y, text, color)       ; Render text string
draw_char_simple(x, y, char, color) ; Render single character
```

## 2. User Interface

### Desktop Environment
- **Background**: Cyan (#03) desktop color
- **Icons**: Computer and Folder placeholders
- **System Info**: Real-time system statistics display

### Taskbar
- **Location**: Bottom 25 pixels of screen
- **Start Button**: Windows-style start button
- **App Slots**: 4 placeholder application buttons
- **Clock**: Digital time display
- **Visual Effects**: 3D button appearance with borders

### Navigation
- **Tab Key**: Cycle through taskbar items (0-4)
- **Enter Key**: Activate selected taskbar item
- **Space Key**: Update system time and refresh display
- **ESC Key**: System reboot

## 3. Memory Management

### Heap Management
- **Start Address**: 0x100000 (1MB)
- **Size**: 512KB (0x100000 - 0x180000)
- **Alignment**: 16-byte boundaries
- **Block Headers**: 16 bytes per allocation

### Block Header Structure
```
Offset 0-3:   Total block size (including header)
Offset 4-7:   Magic number (0xDEADBEEF = allocated, 0xFEEDFACE = free)
Offset 8-11:  Original requested size
Offset 12-15: Reserved for future use
```

### Memory Functions
```assembly
malloc(size)              ; Allocate memory block
free(pointer)             ; Free memory block
get_memory_stats()        ; Get allocation statistics
reset_heap()              ; Clear all allocations
check_memory_bounds(addr, size) ; Validate memory access
```

### Safety Features
- Magic number validation for corruption detection
- NULL pointer checks
- Bounds checking for heap overflow prevention
- Automatic 16-byte alignment

## 4. System Services

### Time Management
- **System Uptime**: Tracked in seconds
- **Time Format**: 24-hour HH:MM:SS
- **Update Method**: Manual via Space key (demo mode)

### Process Management (Basic)
- **Process Table**: Simple counter-based system
- **Kernel Process**: Process ID 0 (always running)
- **Process States**: Running/Terminated
- **Scheduling**: None (single-threaded)

### System Calls (Placeholder)
```assembly
sys_exit    (0)  ; Terminate process
sys_write   (1)  ; Write operation
sys_read    (2)  ; Read operation
sys_time    (3)  ; Time operations
```

## 5. Input/Output

### Keyboard Handling
- **Interface**: PS/2 keyboard controller (port 0x60)
- **Scan Codes**: IBM PC scan code set 1
- **Key Detection**: Polling-based (no interrupts)
- **Buffer**: None (direct processing)

### Key Mappings
```
0x0F - Tab key
0x1C - Enter key
0x39 - Space key
0x01 - ESC key
0x32 - M key (memory test)
```

### Display Output
- **Graphics Mode**: VGA Mode 13h
- **Text Output**: Custom bitmap font rendering
- **Colors**: Standard VGA 256-color palette
- **Refresh**: Manual redraw on events

## 6. File System

### Current State
- **Implementation**: Placeholder functions only
- **File Operations**: create_file(), delete_file()
- **File Counter**: Basic file count tracking
- **Storage**: No persistent storage

### Future Enhancements
- FAT12/16/32 support
- Directory structures
- File metadata
- Disk I/O operations

## 7. Build System

### Tools Required
- **NASM**: Netwide Assembler for x86 assembly
- **QEMU**: System emulator for testing
- **Windows**: Build scripts in batch format

### Build Process
```batch
build.bat:
1. Assemble boot.asm → boot.bin
2. Assemble kernel.asm → kernel.bin
3. Create disk image (1.44MB floppy format)
4. Combine bootloader + kernel → os.img
```

### File Structure
```
/
├── src/
│   ├── boot.asm        ; 16-bit bootloader
│   ├── kernel.asm      ; 32-bit kernel
│   ├── gui.asm         ; GUI components (if separate)
│   └── mouse.asm       ; Mouse driver (if separate)
├── scripts/
│   ├── build.bat       ; Build script
│   └── run.bat         ; QEMU run script
├── build/              ; Build output directory
└── TECHNICAL.md        ; This documentation
```

## 8. System Limitations

### Current Limitations
- **No Interrupts**: Uses polling for all I/O
- **No Protected Memory**: All code runs in ring 0
- **No Virtual Memory**: Direct physical memory access
- **No Multitasking**: Single-threaded execution
- **No File System**: No persistent storage support
- **No Network**: No network stack or drivers
- **No Audio**: No sound support

### Memory Constraints
- **Total RAM**: Assumes minimum 2MB system memory
- **Usable Memory**: ~1.5MB after system areas
- **Stack Size**: 64KB fixed size
- **Heap Size**: 512KB fixed size

## 9. Performance Characteristics

### Boot Time
- **Cold Boot**: ~2-3 seconds in QEMU
- **Loading Screen**: 5-second animated progress bar
- **GUI Initialization**: <1 second

### Memory Usage
- **Kernel Size**: ~4KB compiled
- **Font Data**: ~3KB for character set
- **System Variables**: <1KB
- **Graphics Buffer**: 64KB (VGA framebuffer)

### Responsiveness
- **Key Response**: Immediate (polling loop)
- **Graphics Updates**: Real-time pixel manipulation
- **Text Rendering**: ~100 characters/second

## 10. Development Guidelines

### Code Style
- **Assembly Style**: Intel syntax with NASM directives
- **Comments**: Detailed function headers and inline comments
- **Labels**: Descriptive names with dot notation for local labels
- **Constants**: Use EQU directives for magic numbers

### Memory Safety
- Always validate pointers before dereferencing
- Use magic numbers for structure validation
- Implement bounds checking for all memory operations
- Clear sensitive data after use

### Error Handling
- Check return values from all functions
- Implement graceful degradation for non-critical failures
- Use consistent error codes across modules
- Log errors to system status when possible

## 11. Testing Procedures

### Unit Testing
- Test individual functions in isolation
- Verify memory allocation/deallocation cycles
- Test boundary conditions and error cases
- Validate graphics rendering functions

### Integration Testing
- Test complete boot sequence
- Verify GUI interaction flows
- Test keyboard input handling
- Validate system state consistency

### Performance Testing
- Measure boot times
- Test memory allocation performance
- Verify graphics rendering speed
- Monitor system resource usage

## 12. Future Roadmap

### Short Term (Version 2.0)
- Implement interrupt handling (PIT, keyboard)
- Add basic file system support
- Implement proper multitasking
- Add more GUI widgets

### Medium Term (Version 3.0)
- Add network stack
- Implement virtual memory
- Add audio support
- Create application framework

### Long Term (Version 4.0+)
- Support for modern hardware
- 64-bit architecture support
- Advanced graphics (VESA modes)
- POSIX-like system call interface

## 13. Security Considerations

### Current Security Model
- **No Protection**: All code runs with full privileges
- **No Isolation**: No memory protection between components
- **No Validation**: Limited input validation
- **No Encryption**: No data protection mechanisms

### Planned Security Features
- Ring-based privilege levels
- Memory protection units
- Input validation framework
- Basic cryptographic primitives

## 14. Debugging and Troubleshooting

### Common Issues
1. **Boot Failure**: Check bootloader disk read operations
2. **Graphics Corruption**: Verify VGA mode setup
3. **Memory Crashes**: Check heap boundary conditions
4. **Keyboard Unresponsive**: Verify scan code handling

### Debugging Tools
- **QEMU Monitor**: For system state inspection
- **NASM Listings**: For assembly debugging
- **Hex Editor**: For disk image analysis
- **GDB**: For step-by-step debugging (with QEMU)

### Log Analysis
- System uptime for stability testing
- Memory allocation patterns
- Keyboard input sequences
- Graphics operation counts

---

**Document Version**: 1.0  
**Last Updated**: August 11th, 2025  
**Maintained By**: Scooter!
