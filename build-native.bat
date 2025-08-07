@echo off
setlocal enabledelayedexpansion

echo Simple 16-bit Kernel Builder (Native Windows)
echo =============================================
echo.

REM Check if build directory exists, create if not
if not exist build mkdir build

REM Build bootloader
echo Building bootloader...
nasm -f bin boot.asm -o build\boot.bin
if %errorlevel% neq 0 (
    echo Error: Failed to build bootloader
    pause
    exit /b 1
)
echo Bootloader built successfully.

REM Build kernel
echo Building kernel...
nasm -f bin kernel.asm -o build\kernel.bin
if %errorlevel% neq 0 (
    echo Error: Failed to build kernel
    pause
    exit /b 1
)
echo Kernel built successfully.

REM Create OS image
echo Creating OS image...
copy /b build\boot.bin + build\kernel.bin build\os.img >nul
if %errorlevel% neq 0 (
    echo Error: Failed to create OS image
    pause
    exit /b 1
)
echo OS image created successfully.

REM Check if user wants to run
set /p run="Run in QEMU? (y/n): "
if /i "%run%"=="y" (
    echo Starting QEMU...
    qemu-system-i386 -drive format=raw,file=build\os.img,if=ide,index=0,media=disk
)

echo.
echo Build complete! You can manually run with:
echo qemu-system-i386 -drive format=raw,file=build\os.img,if=ide,index=0,media=disk
echo.
pause
