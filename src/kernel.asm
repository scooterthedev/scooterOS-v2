[BITS 32]
[ORG 0x1000]

; Simple GUI-Enabled 32-bit Kernel Entry Point
kernel_start:
    ; Set up stack
    mov esp, 0x90000

    ; Show loading screen IMMEDIATELY (before anything else)
    call show_loading_screen

    ; After loading, show the main GUI
    call show_main_gui

    ; Simple infinite loop
    jmp infinite_loop

; Show loading screen with black background and animated progress bar
show_loading_screen:
    ; Clear screen to black FIRST
    call clear_screen_black
    
    ; Draw "Loading..." text (normal size, clear)
    mov eax, 120        ; x position
    mov ebx, 70         ; y position
    mov esi, loading_message
    mov edi, 0x0F       ; white color
    call draw_text
    
    ; Draw loading bar background (gray border)
    mov eax, 60         ; x position
    mov ebx, 100        ; y position
    mov ecx, 200        ; width
    mov edx, 20         ; height
    mov esi, 0x08       ; dark gray color
    call draw_filled_rectangle
    
    ; Animate loading bar (5 seconds total, 200 steps)
    mov ebx, 0          ; progress counter
.loading_loop:
    cmp ebx, 196        ; full width (minus border)
    jge .loading_done
    
    ; Draw progress bar (green)
    mov eax, 62         ; x position (inside border)
    push ebx
    mov ebx, 102        ; y position (inside border)
    mov ecx, [esp]      ; current progress width
    mov edx, 16         ; height (inside border)
    mov esi, 0x02       ; green color
    call draw_filled_rectangle
    pop ebx
    
    ; 5 second delay: 196 steps for full bar, ~25ms per step = 5 seconds
    push ebx
    mov ecx, 0x200000   ; Larger delay for ~25ms per step
.delay_loop:
    loop .delay_loop
    pop ebx
    
    inc ebx             ; increase progress by 1 pixel (slower)
    jmp .loading_loop
    
.loading_done:
    ; Show "Complete!" message
    mov eax, 100        ; x position
    mov ebx, 130        ; y position
    mov esi, complete_message
    mov edi, 0x0A       ; bright green color
    call draw_text
    
    ; Final delay
    mov ecx, 0x300000
.final_delay:
    loop .final_delay
    
    ret

; Clear screen to black
clear_screen_black:
    mov edi, 0xA0000    ; VGA graphics buffer
    mov ecx, 64000      ; 320x200 pixels
    mov al, 0x00        ; Black background
    rep stosb
    ret

; Show main GUI after loading
show_main_gui:
    ; Clear screen to green
    mov edi, 0xA0000    ; VGA graphics buffer
    mov ecx, 64000      ; 320x200 pixels
    mov al, 0x02        ; Green background
    rep stosb
    
    ; Draw test rectangles
    mov eax, 50         ; x
    mov ebx, 50         ; y
    mov ecx, 100        ; width
    mov edx, 80         ; height
    mov esi, 0x04       ; red color
    call draw_filled_rectangle
    
    mov eax, 170        ; x
    mov ebx, 70         ; y
    mov ecx, 80         ; width
    mov edx, 60         ; height
    mov esi, 0x01       ; blue color
    call draw_filled_rectangle
    
    ; Draw messages
    mov eax, 60         ; x position
    mov ebx, 160        ; y position
    mov esi, gui_message
    mov edi, 0x0F       ; white color
    call draw_text
    
    mov eax, 60
    mov ebx, 175
    mov esi, exit_message
    mov edi, 0x0E       ; yellow color
    call draw_text
    
    ret

; Draw regular text (simplified version)
; EAX = x, EBX = y, ESI = text pointer, EDI = color
draw_text:
    push eax
    push ebx
    
.char_loop:
    mov cl, [esi]       ; Load character
    cmp cl, 0           ; Check for null terminator
    je .done
    
    ; Draw character using simple method
    push esi
    push edi
    push eax
    push ebx
    movzx ecx, cl       ; Character code
    call draw_char_simple
    pop ebx
    pop eax
    pop edi
    pop esi
    
    add eax, 8          ; Move to next character position (8 pixels)
    inc esi             ; Next character
    jmp .char_loop
    
.done:
    pop ebx
    pop eax
    ret

; Simple character drawing function with better font data
; EAX = x, EBX = y, ECX = character code, EDI = color
draw_char_simple:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    
    ; Handle only printable characters (space to Z)
    cmp cl, 0x20        ; Space
    jl .char_done
    cmp cl, 0x5A        ; Z
    jg .char_done
    
    ; Get font pattern for character
    sub cl, 0x20        ; Adjust to font table index
    movzx ecx, cl
    mov esi, simple_font
    imul ecx, 8         ; Each character is 8 bytes
    add esi, ecx
    
    ; Draw 8x8 character
    mov edx, 0          ; Row counter
.row_loop:
    cmp edx, 8
    jge .char_done
    
    mov cl, [esi + edx] ; Get row pattern
    push eax            ; Save x position
    
    ; Draw 8 pixels in this row
    mov ch, 8           ; Pixel counter
.pixel_loop:
    test cl, 0x80       ; Test leftmost bit
    jz .skip_pixel
    
    ; Draw pixel
    call draw_single_pixel
    
.skip_pixel:
    shl cl, 1           ; Shift to next bit
    inc eax             ; Next x position
    dec ch
    jnz .pixel_loop
    
    pop eax             ; Restore x position
    inc ebx             ; Next row
    inc edx
    jmp .row_loop
    
.char_done:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Draw a single pixel at EAX,EBX with color EDI
draw_single_pixel:
    pusha
    
    ; Bounds check
    cmp eax, 0
    jl .done
    cmp eax, 320
    jge .done
    cmp ebx, 0
    jl .done
    cmp ebx, 200
    jge .done
    
    ; Calculate pixel address: 0xA0000 + (y * 320) + x
    push eax
    mov eax, ebx
    mov edx, 320
    mul edx             ; EAX = y * 320
    pop edx             ; EDX = x
    add eax, edx        ; EAX = (y * 320) + x
    add eax, 0xA0000    ; Add VGA base address
    
    ; Set pixel
    mov edx, eax        ; EDX = pixel address
    mov eax, edi        ; EAX = color
    mov [edx], al       ; Store color byte
    
.done:
    popa
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
    mov [edi], al       ; Set pixel color
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
loading_message db 'Loading...', 0
complete_message db 'Complete!', 0
gui_message db 'GUI OS v1.0', 0
exit_message db 'Press ESC to exit', 0

; Simple font data (space to Z) - much cleaner patterns
simple_font:
    ; 0x20 - Space
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    ; 0x21 - !
    db 0x18, 0x18, 0x18, 0x18, 0x18, 0x00, 0x18, 0x00
    ; 0x22 - "
    db 0x6C, 0x6C, 0x24, 0x00, 0x00, 0x00, 0x00, 0x00
    ; 0x23-0x2F (symbols)
    times 13*8 db 0x00
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
    ; 0x3A-0x40 (symbols)
    times 7*8 db 0x00
    ; 0x41 - A
    db 0x3C, 0x66, 0x66, 0x66, 0x7E, 0x66, 0x66, 0x00
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

; Pad to ensure proper alignment
times 4096-($-$$) db 0
