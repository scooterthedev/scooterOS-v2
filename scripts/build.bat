@echo off
setlocal enabledelayedexpansion

echo GUI-Enabled 32-bit OS Builder
echo ==============================
echo.

REM Check if build directory exists, create if not
if not exist build mkdir build

REM Build bootloader
echo [1/3] Building GUI bootloader...
nasm -f bin src\boot.asm -o build\boot.bin
if %errorlevel% neq 0 (
    echo Error: Failed to build bootloader
    pause
    exit /b 1
)
echo ✓ Bootloader built successfully.

REM Build GUI kernel
echo [2/3] Building GUI kernel...
nasm -f bin src\kernel.asm -o build\kernel.bin
if %errorlevel% neq 0 (
    echo Error: Failed to build GUI kernel
    pause
    exit /b 1
)
echo ✓ GUI kernel built successfully.

REM Create OS image
echo [3/3] Creating GUI OS image...
copy /b build\boot.bin + build\kernel.bin build\os.img >nul
if %errorlevel% neq 0 (
    echo Error: Failed to create OS image
    pause
    exit /b 1
)
echo ✓ GUI OS image created successfully.

echo.
echo Build successful!
echo.
set /p run="Run GUI OS in QEMU? (y/n): "
if /i "%run%"=="y" (
    echo Starting QEMU with VGA graphics support...
    qemu-system-i386 -drive format=raw,file=build\os.img,if=ide,index=0,media=disk -vga std
)

echo.
echo Manual run command:
echo   qemu-system-i386 -drive format=raw,file=build\os.img,if=ide,index=0,media=disk -vga std
echo.
echo Features:
echo   - 320x200x256 VGA graphics mode
echo   - Real bitmap font text rendering
echo   - Mouse cursor support
echo   - Keyboard interaction (ESC to exit)
echo.
pause
