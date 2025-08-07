[BITS 32]

; External C function
extern kernel_main

; Export kernel_start for linker
global kernel_start

; Simple GUI-Enabled 32-bit Kernel Entry Point
kernel_start:
    ; Set up stack
    mov esp, 0x90000

    ; Call C kernel main function which handles loading screen and GUI
    call kernel_main

    ; Simple infinite loop (no complex mouse/keyboard for now)
    jmp infinite_loop

; Simple infinite loop with basic keyboard check
infinite_loop:
    ; Check for ESC key to reboot
    in al, 0x60         ; Read keyboard
    cmp al, 0x01        ; ESC key scan code
    je reboot_system
    
    ; Small delay
    mov ecx, 0x10000
.delay:
    loop .delay
    
    jmp infinite_loop

reboot_system:
    ; Reboot via keyboard controller
    mov al, 0xFE
    out 0x64, al
    
    ; If that fails, halt
    cli
    hlt

; Pad to ensure proper alignment
times 4096-($-$$) db 0
