[BITS 32]
[ORG 0x1000]

; Simple GUI-Enabled 32-bit Kernel Entry Point
kernel_start:
    ; Set up stack
    mov esp, 0x90000

    ; Clear screen with a simple pattern
    call clear_graphics_screen

    ; Draw a simple test pattern
    call draw_test_pattern

    ; Draw a simple message
    call draw_simple_message

    ; Simple infinite loop (no complex mouse/keyboard for now)
    jmp infinite_loop

; Clear graphics screen with background color
clear_graphics_screen:
    mov edi, 0xA0000    ; VGA graphics buffer
    mov ecx, 64000      ; 320x200 pixels
    mov al, 0x02        ; Green background
    rep stosb
    ret

; Draw a simple test pattern
draw_test_pattern:
    ; Draw a red rectangle
    mov eax, 50         ; x
    mov ebx, 50         ; y
    mov ecx, 100        ; width
    mov edx, 80         ; height
    mov esi, 0x04       ; red color
    call draw_filled_rectangle
    
    ; Draw a blue rectangle
    mov eax, 170        ; x
    mov ebx, 70         ; y
    mov ecx, 80         ; width
    mov edx, 60         ; height
    mov esi, 0x01       ; blue color
    call draw_filled_rectangle
    
    ret

; Draw simple message as colored blocks
draw_simple_message:
    ; Draw "GUI OS" as colored rectangles
    ; G
    mov eax, 60
    mov ebx, 160
    mov ecx, 8
    mov edx, 16
    mov esi, 0x0F       ; white
    call draw_filled_rectangle
    
    ; U  
    mov eax, 75
    mov ebx, 160
    mov ecx, 8
    mov edx, 16
    mov esi, 0x0F
    call draw_filled_rectangle
    
    ; I
    mov eax, 90
    mov ebx, 160
    mov ecx, 8
    mov edx, 16
    mov esi, 0x0F
    call draw_filled_rectangle
    
    ; Space
    
    ; O
    mov eax, 115
    mov ebx, 160
    mov ecx, 8
    mov edx, 16
    mov esi, 0x0F
    call draw_filled_rectangle
    
    ; S
    mov eax, 130
    mov ebx, 160
    mov ecx, 8
    mov edx, 16
    mov esi, 0x0F
    call draw_filled_rectangle
    
    ret

; Draw filled rectangle
; EAX = x, EBX = y, ECX = width, EDX = height, ESI = color
draw_filled_rectangle:
    push eax
    push ebx
    push ecx
    push edx
    
    add edx, ebx        ; end_y = y + height
    
.row_loop:
    cmp ebx, edx
    jge .done
    
    push ebx
    push edx
    mov edx, ecx        ; width
    add edx, eax        ; end_x = x + width
    
.col_loop:
    cmp eax, edx
    jge .row_done
    
    ; Bounds checking
    cmp eax, 0
    jl .skip_pixel
    cmp eax, 320
    jge .skip_pixel
    cmp ebx, 0
    jl .skip_pixel
    cmp ebx, 200
    jge .skip_pixel
    
    ; Calculate pixel offset: y * 320 + x
    push eax
    push edx
    mov edi, ebx
    imul edi, 320
    add edi, eax
    add edi, 0xA0000
    push esi
    mov eax, esi        ; Move color to EAX
    mov [edi], al       ; Set pixel color (only need lower 8 bits)
    pop esi
    pop edx
    pop eax
    
.skip_pixel:
    inc eax
    jmp .col_loop
    
.row_done:
    pop edx
    pop ebx
    mov eax, [esp+12]   ; restore original x
    inc ebx
    jmp .row_loop
    
.done:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

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
times 2048-($-$$) db 0
