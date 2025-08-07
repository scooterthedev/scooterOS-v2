[BITS 32]
[ORG 0x1000]

; Simple GUI-Enabled 32-bit Kernel Entry Point
kernel_start:
    ; Set up stack
    mov esp, 0x90000

    ; Show loading screen
    call show_loading_screen

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

; Draw simple message with real text
draw_simple_message:
    ; Draw "GUI OS v1.0" with real text
    mov eax, 60         ; x position
    mov ebx, 160        ; y position
    mov esi, gui_message
    mov edi, 0x0F       ; white color
    call draw_text
    
    ; Draw "Press ESC to exit"
    mov eax, 60
    mov ebx, 175
    mov esi, exit_message
    mov edi, 0x0E       ; yellow color
    call draw_text
    
    ret

; Draw text using bitmap font
; EAX = x, EBX = y, ESI = text pointer, EDI = color
draw_text:
    push eax
    push ebx
    
.char_loop:
    mov cl, [esi]       ; Load character
    cmp cl, 0           ; Check for null terminator
    je .done
    
    ; Draw character using bitmap font
    push esi
    push edi
    movzx ecx, cl       ; Character code
    call draw_char
    pop edi
    pop esi
    
    add eax, 8          ; Move to next character position (8 pixels wide)
    inc esi             ; Next character
    jmp .char_loop
    
.done:
    pop ebx
    pop eax
    ret

; Draw a single character using 8x8 bitmap font
; EAX = x, EBX = y, ECX = character code, EDI = color
draw_char:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    
    ; Get font data for character
    ; Each character is 8 bytes (8x8 pixels)
    mov esi, font_data
    imul ecx, 8         ; Each char is 8 bytes
    add esi, ecx        ; Point to character data
    
    ; Draw 8 rows
    mov edx, 0          ; Row counter
.row_loop:
    cmp edx, 8
    jge .char_done
    
    mov cl, [esi + edx] ; Get row bitmap
    
    ; Draw 8 pixels in this row
    push eax            ; Save original x
    mov ecx, 0          ; Pixel counter
.pixel_loop:
    cmp ecx, 8
    jge .next_row
    
    ; Check if pixel should be drawn (test bit)
    push ecx
    mov ch, cl
    mov cl, 7
    sub cl, ch          ; Reverse bit order (MSB first)
    push eax
    mov al, [esi + edx]
    shr al, cl
    and al, 1
    cmp al, 1
    pop eax
    pop ecx
    jne .skip_pixel
    
    ; Draw pixel
    push ecx
    push edx
    push esi
    mov ecx, 1          ; width
    mov edx, 1          ; height
    mov esi, edi        ; color
    call draw_filled_rectangle
    pop esi
    pop edx
    pop ecx
    
.skip_pixel:
    inc eax             ; Next pixel x
    inc ecx             ; Next pixel
    jmp .pixel_loop
    
.next_row:
    pop eax             ; Restore original x
    inc ebx             ; Next row y
    inc edx             ; Next row
    jmp .row_loop
    
.char_done:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
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

; Data section
gui_message db 'GUI OS v1.0', 0
exit_message db 'Press ESC to exit', 0

; Simple 8x8 bitmap font data (ASCII 0-127)
; Only including essential characters: space, letters, numbers
font_data:
    ; Character 0x00-0x1F (control chars) - all blank
    times 32*8 db 0x00
    
    ; 0x20 - Space
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    ; 0x21 - !
    db 0x18, 0x18, 0x18, 0x18, 0x18, 0x00, 0x18, 0x00
    ; 0x22-0x2F - Various symbols (simplified)
    times 14*8 db 0x00
    
    ; 0x30 - 0
    db 0x3C, 0x66, 0x6E, 0x76, 0x66, 0x66, 0x3C, 0x00
    ; 0x31 - 1  
    db 0x18, 0x38, 0x18, 0x18, 0x18, 0x18, 0x7E, 0x00
    ; 0x32 - 2
    db 0x3C, 0x66, 0x06, 0x0C, 0x18, 0x30, 0x7E, 0x00
    ; 0x33 - 3
    db 0x3C, 0x66, 0x06, 0x1C, 0x06, 0x66, 0x3C, 0x00
    ; 0x34 - 4
    db 0x0C, 0x1C, 0x3C, 0x6C, 0x7E, 0x0C, 0x0C, 0x00
    ; 0x35 - 5
    db 0x7E, 0x60, 0x7C, 0x06, 0x06, 0x66, 0x3C, 0x00
    ; 0x36 - 6
    db 0x3C, 0x60, 0x7C, 0x66, 0x66, 0x66, 0x3C, 0x00
    ; 0x37 - 7
    db 0x7E, 0x06, 0x0C, 0x18, 0x30, 0x30, 0x30, 0x00
    ; 0x38 - 8
    db 0x3C, 0x66, 0x66, 0x3C, 0x66, 0x66, 0x3C, 0x00
    ; 0x39 - 9
    db 0x3C, 0x66, 0x66, 0x3E, 0x06, 0x0C, 0x38, 0x00
    
    ; 0x3A-0x40 - Symbols
    times 7*8 db 0x00
    
    ; 0x41 - A
    db 0x18, 0x3C, 0x66, 0x66, 0x7E, 0x66, 0x66, 0x00
    ; 0x42 - B
    db 0x7C, 0x66, 0x66, 0x7C, 0x66, 0x66, 0x7C, 0x00
    ; 0x43 - C
    db 0x3C, 0x66, 0x60, 0x60, 0x60, 0x66, 0x3C, 0x00
    ; 0x44 - D
    db 0x78, 0x6C, 0x66, 0x66, 0x66, 0x6C, 0x78, 0x00
    ; 0x45 - E
    db 0x7E, 0x60, 0x60, 0x7C, 0x60, 0x60, 0x7E, 0x00
    ; 0x46 - F
    db 0x7E, 0x60, 0x60, 0x7C, 0x60, 0x60, 0x60, 0x00
    ; 0x47 - G
    db 0x3C, 0x66, 0x60, 0x6E, 0x66, 0x66, 0x3C, 0x00
    ; 0x48 - H
    db 0x66, 0x66, 0x66, 0x7E, 0x66, 0x66, 0x66, 0x00
    ; 0x49 - I
    db 0x7E, 0x18, 0x18, 0x18, 0x18, 0x18, 0x7E, 0x00
    ; 0x4A - J
    db 0x1E, 0x0C, 0x0C, 0x0C, 0x0C, 0x6C, 0x38, 0x00
    ; 0x4B - K
    db 0x66, 0x6C, 0x78, 0x70, 0x78, 0x6C, 0x66, 0x00
    ; 0x4C - L
    db 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x7E, 0x00
    ; 0x4D - M
    db 0x63, 0x77, 0x7F, 0x6B, 0x63, 0x63, 0x63, 0x00
    ; 0x4E - N
    db 0x66, 0x76, 0x7E, 0x7E, 0x6E, 0x66, 0x66, 0x00
    ; 0x4F - O
    db 0x3C, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x00
    ; 0x50 - P
    db 0x7C, 0x66, 0x66, 0x7C, 0x60, 0x60, 0x60, 0x00
    ; 0x51 - Q
    db 0x3C, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x0E, 0x00
    ; 0x52 - R
    db 0x7C, 0x66, 0x66, 0x7C, 0x78, 0x6C, 0x66, 0x00
    ; 0x53 - S
    db 0x3C, 0x66, 0x60, 0x3C, 0x06, 0x66, 0x3C, 0x00
    ; 0x54 - T
    db 0x7E, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00
    ; 0x55 - U
    db 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x00
    ; 0x56 - V
    db 0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x18, 0x00
    ; 0x57 - W
    db 0x63, 0x63, 0x63, 0x6B, 0x7F, 0x77, 0x63, 0x00
    ; 0x58 - X
    db 0x66, 0x66, 0x3C, 0x18, 0x3C, 0x66, 0x66, 0x00
    ; 0x59 - Y
    db 0x66, 0x66, 0x66, 0x3C, 0x18, 0x18, 0x18, 0x00
    ; 0x5A - Z
    db 0x7E, 0x06, 0x0C, 0x18, 0x30, 0x60, 0x7E, 0x00
    
    ; Fill remaining characters with blanks
    times (256-91)*8 db 0x00

; Pad to ensure proper alignment
times 4096-($-$$) db 0
