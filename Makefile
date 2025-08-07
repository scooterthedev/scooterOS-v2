# GUI-Enabled 32-bit OS Makefile for Windows

# Tools
ASM = nasm
CC = gcc
LD = ld

# Directories
BUILD_DIR = build

# Files
BOOT_SRC = src/boot.asm
KERNEL_ASM_SRC = src/kernel.asm
KERNEL_C_SRC = src/kernel_main.c
TEXT_DRIVER_SRC = src/text_driver.c
BOOT_BIN = $(BUILD_DIR)/boot.bin
KERNEL_ASM_OBJ = $(BUILD_DIR)/kernel_asm.o
KERNEL_C_OBJ = $(BUILD_DIR)/kernel_main.o
KERNEL_BIN = $(BUILD_DIR)/kernel.bin
OS_IMG = $(BUILD_DIR)/os.img

# Compiler flags
CFLAGS = -m32 -nostdlib -nostartfiles -nodefaultlibs -fno-builtin -fno-stack-protector -mno-red-zone -mno-mmx -mno-sse -mno-sse2 -ffreestanding -Os

# Default target
all: $(OS_IMG)

# Create build directory
$(BUILD_DIR):
	if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)

# Build bootloader
$(BOOT_BIN): $(BOOT_SRC) | $(BUILD_DIR)
	$(ASM) -f bin $(BOOT_SRC) -o $(BOOT_BIN)

# Build kernel assembly part
$(KERNEL_ASM_OBJ): $(KERNEL_ASM_SRC) | $(BUILD_DIR)
	$(ASM) -f elf32 $(KERNEL_ASM_SRC) -o $(KERNEL_ASM_OBJ)

# Build kernel C part
$(KERNEL_C_OBJ): $(KERNEL_C_SRC) $(TEXT_DRIVER_SRC) | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $(KERNEL_C_SRC) -o $(KERNEL_C_OBJ)

# Link kernel
$(KERNEL_BIN): $(KERNEL_ASM_OBJ) $(KERNEL_C_OBJ) | $(BUILD_DIR)
	$(LD) -m elf_i386 -T linker.ld $(KERNEL_ASM_OBJ) $(KERNEL_C_OBJ) -o $(KERNEL_BIN)

# Create OS image
$(OS_IMG): $(BOOT_BIN) $(KERNEL_BIN)
	@echo Creating GUI-enabled OS image...
	copy /b "$(BOOT_BIN)" + "$(KERNEL_BIN)" "$(OS_IMG)"

# Run in QEMU with GUI support
run: $(OS_IMG)
	qemu-system-i386 -drive format=raw,file="$(OS_IMG)",if=ide,index=0,media=disk -vga std

# Run with debugging
debug: $(OS_IMG)
	qemu-system-i386 -drive format=raw,file="$(OS_IMG)",if=ide,index=0,media=disk -s -S -vga std

# Clean build files
clean:
	-if exist $(BUILD_DIR) rmdir /s /q $(BUILD_DIR)

# Help
help:
	@echo Available targets:
	@echo   all     - Build the GUI-enabled OS image
	@echo   run     - Build and run in QEMU with VGA support
	@echo   debug   - Build and run with debugging
	@echo   clean   - Clean build files
	@echo   help    - Show this help

.PHONY: all run debug clean help
