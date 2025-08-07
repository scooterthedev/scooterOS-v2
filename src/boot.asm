[BITS 16]
[ORG 0x7C00]

; 32-bit OS Bootloader
; This bootloader sets up protected mode and loads the 32-bit kernel

start:
    ; Initialize segments
    cli                     ; Disable interrupts
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00         ; Set stack pointer

    ; Display boot message
    mov si, boot_msg
    call print_string_16

    ; Set VGA mode 13h while in real mode (before protected mode)
    mov ah, 0x00
    mov al, 0x13        ; VGA mode 13h (320x200x256)
    int 0x10

    ; Enable A20 line (required for protected mode)
    call enable_a20

    ; Load kernel from disk
    call load_kernel

    ; Set up GDT
    lgdt [gdt_descriptor]

    ; Switch to protected mode
    mov eax, cr0
    or eax, 1              ; Set PE bit
    mov cr0, eax

    ; Far jump to flush prefetch queue and load CS
    jmp CODE_SEG:protected_mode

; 16-bit functions
print_string_16:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

enable_a20:
    ; Method 1: Keyboard controller
    call a20_wait
    mov al, 0xAD
    out 0x64, al

    call a20_wait
    mov al, 0xD0
    out 0x64, al

    call a20_wait2
    in al, 0x60
    push eax

    call a20_wait
    mov al, 0xD1
    out 0x64, al

    call a20_wait
    pop eax
    or al, 2
    out 0x60, al

    call a20_wait
    mov al, 0xAE
    out 0x64, al

    call a20_wait
    ret

a20_wait:
    in al, 0x64
    test al, 2
    jnz a20_wait
    ret

a20_wait2:
    in al, 0x64
    test al, 1
    jz a20_wait2
    ret

load_kernel:
    ; Try loading from drive 0x00 first (floppy/first drive in QEMU)
    mov ah, 0x02           ; Read sectors function
    mov al, 4              ; Number of sectors to read
    mov ch, 0              ; Cylinder 0
    mov cl, 2              ; Start from sector 2
    mov dh, 0              ; Head 0
    mov dl, 0x00           ; Drive number (first try: floppy)
    mov bx, KERNEL_OFFSET  ; Load to 0x1000
    int 0x13
    
    jnc .success           ; If no carry, success
    
    ; If first attempt failed, try hard disk (0x80)
    mov ah, 0x02
    mov al, 4
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0x80           ; Drive number (second try: hard disk)
    mov bx, KERNEL_OFFSET
    int 0x13
    
    jc disk_error          ; If still failed, show error
    
.success:
    ret

disk_error:
    mov si, error_msg
    call print_string_16
    cli
    hlt

; 32-bit protected mode code
[BITS 32]
protected_mode:
    ; Set up segment registers for protected mode
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Set up stack
    mov ebp, 0x90000
    mov esp, ebp

    ; Jump to kernel
    jmp KERNEL_OFFSET

; Global Descriptor Table
gdt_start:

gdt_null:                  ; Null descriptor
    dd 0x0
    dd 0x0

gdt_code:                  ; Code segment descriptor
    dw 0xFFFF              ; Limit (bits 0-15)
    dw 0x0000              ; Base (bits 0-15)
    db 0x00                ; Base (bits 16-23)
    db 10011010b           ; Access byte
    db 11001111b           ; Granularity + limit (bits 16-19)
    db 0x00                ; Base (bits 24-31)

gdt_data:                  ; Data segment descriptor
    dw 0xFFFF              ; Limit (bits 0-15)
    dw 0x0000              ; Base (bits 0-15)
    db 0x00                ; Base (bits 16-23)
    db 10010010b           ; Access byte
    db 11001111b           ; Granularity + limit (bits 16-19)
    db 0x00                ; Base (bits 24-31)

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Size
    dd gdt_start                ; Offset

; Constants
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start
KERNEL_OFFSET equ 0x1000

; Messages
boot_msg db 'Loading 32-bit OS...', 13, 10, 0
error_msg db 'Disk read error!', 13, 10, 0

; Pad and add boot signature
times 510-($-$$) db 0
dw 0xAA55
