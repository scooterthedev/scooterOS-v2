[BITS 16]       ; 16-bit mode
[ORG 0x7C00]    ; BIOS loads bootloader at 0x7C00

; Simple bootloader that loads kernel and jumps to it
start:
    ; Set up segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00  ; Stack pointer below bootloader

    ; Display boot message
    mov si, boot_msg
    call print_string

    ; Load kernel from disk (sector 2) to memory at 0x1000
    mov ah, 0x02    ; Read sectors function
    mov al, 2       ; Number of sectors to read (increased to 2)
    mov ch, 0       ; Cylinder 0
    mov cl, 2       ; Sector 2 (kernel location)
    mov dh, 0       ; Head 0
    mov dl, 0x80    ; Drive number (first hard disk)
    mov bx, 0x1000  ; Load kernel at 0x1000
    int 0x13        ; BIOS disk interrupt
    
    jc disk_error   ; Jump if carry flag set (error)

    ; Jump to kernel
    jmp 0x1000

disk_error:
    mov si, error_msg
    call print_string
    cli
    hlt

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

boot_msg db 'Booting simple kernel...', 13, 10, 0
error_msg db 'Disk read error!', 13, 10, 0

; Pad to 510 bytes and add boot signature
times 510-($-$$) db 0
dw 0xAA55       ; Boot signature
