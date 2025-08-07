# Simple 16-bit Kernel Makefile for Windows

# Tools
ASM = nasm
CC = gcc
LD = ld

# Directories
BUILD_DIR = build

# Files
BOOT_SRC = boot.asm
KERNEL_SRC = kernel.asm
BOOT_BIN = $(BUILD_DIR)\boot.bin
KERNEL_BIN = $(BUILD_DIR)\kernel.bin
OS_IMG = $(BUILD_DIR)\os.img

# Default target
all: $(OS_IMG)

# Create build directory
$(BUILD_DIR):
	if not exist $(BUILD_DIR) mkdir $(BUILD_DIR)

# Build bootloader
$(BOOT_BIN): $(BOOT_SRC) | $(BUILD_DIR)
	$(ASM) -f bin $(BOOT_SRC) -o $(BOOT_BIN)

# Build kernel
$(KERNEL_BIN): $(KERNEL_SRC) | $(BUILD_DIR)
	$(ASM) -f bin $(KERNEL_SRC) -o $(KERNEL_BIN)

# Create OS image
$(OS_IMG): $(BOOT_BIN) $(KERNEL_BIN)
	@echo Creating OS image...
	copy /b "$(BOOT_BIN)" + "$(KERNEL_BIN)" "$(OS_IMG)"

# Run in QEMU
run: $(OS_IMG)
	qemu-system-i386 -drive format=raw,file="$(OS_IMG)",if=ide,index=0,media=disk

# Run in QEMU with debugging
debug: $(OS_IMG)
	qemu-system-i386 -drive format=raw,file="$(OS_IMG)",if=ide,index=0,media=disk -s -S

# Clean build files
clean:
	if exist $(BUILD_DIR) rmdir /s /q $(BUILD_DIR)

# Help
help:
	@echo Available targets:
	@echo   all     - Build the OS image
	@echo   run     - Build and run in QEMU
	@echo   debug   - Build and run in QEMU with debugging
	@echo   clean   - Clean build files
	@echo   help    - Show this help

.PHONY: all run debug clean help
