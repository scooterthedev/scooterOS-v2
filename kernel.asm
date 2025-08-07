[BITS 16]
[ORG 0x1000]    ; Kernel loads at 0x1000

; Simple kernel entry point
kernel_start:
    ; Set up segments
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; Clear screen
    call clear_screen

    ; Set cursor position to top-left
    mov ah, 0x02    ; Set cursor position
    mov bh, 0       ; Page number
    mov dh, 0       ; Row
    mov dl, 0       ; Column
    int 0x10

    ; Display welcome message
    mov si, welcome_msg
    call print_string

    ; Display system info
    mov si, system_msg
    call print_string

    ; Display command prompt
    mov si, prompt_msg
    call print_string

    ; Simple command loop
command_loop:
    call get_key
    
    ; Check for 'h' key (help)
    cmp al, 'h'
    je show_help
    
    ; Check for 'r' key (reboot)
    cmp al, 'r'
    je reboot
    
    ; Check for 'c' key (clear)
    cmp al, 'c'
    je clear_and_return
    
    ; Echo the character
    mov ah, 0x0E
    int 0x10
    
    jmp command_loop

show_help:
    mov si, help_msg
    call print_string
    jmp command_loop

clear_and_return:
    call clear_screen
    mov si, welcome_msg
    call print_string
    mov si, prompt_msg
    call print_string
    jmp command_loop

reboot:
    mov si, reboot_msg
    call print_string
    ; Wait a moment
    mov cx, 0xFFFF
.wait:
    loop .wait
    ; Reboot by jumping to BIOS
    jmp 0xFFFF:0x0000

clear_screen:
    mov ah, 0x00    ; Set video mode
    mov al, 0x03    ; 80x25 color text mode
    int 0x10
    ret

print_string:
    mov ah, 0x0E    ; Teletype output
.loop:
    lodsb           ; Load byte from SI into AL
    cmp al, 0       ; Check for null terminator
    je .done
    int 0x10        ; BIOS video interrupt
    jmp .loop
.done:
    ret

get_key:
    mov ah, 0x00    ; Get keystroke
    int 0x16        ; Keyboard interrupt
    ret

; String data
welcome_msg db 'Simple 16-bit Kernel v1.0', 13, 10
           db '========================', 13, 10, 13, 10, 0

system_msg db 'System Information:', 13, 10
          db '- Architecture: x86 16-bit', 13, 10
          db '- Memory Model: Real Mode', 13, 10
          db '- Video Mode: 80x25 Text', 13, 10, 13, 10, 0

prompt_msg db 'Available commands:', 13, 10
          db 'h - Show help', 13, 10
          db 'c - Clear screen', 13, 10
          db 'r - Reboot system', 13, 10, 13, 10
          db 'Press any key: ', 0

help_msg db 13, 10, 'Help - Simple Kernel Commands:', 13, 10
        db 'h - Display this help message', 13, 10
        db 'c - Clear the screen', 13, 10
        db 'r - Reboot the system', 13, 10
        db 'Any other key will be echoed', 13, 10, 13, 10, 0

reboot_msg db 13, 10, 'Rebooting system...', 13, 10, 0

; End of kernel (no padding needed)
