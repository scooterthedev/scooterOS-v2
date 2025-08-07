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
    
    ; Draw "Loading..." text (large and clear)
    mov eax, 80         ; x position
    mov ebx, 70         ; y position
    mov esi, loading_message
    mov edi, 0x0F       ; white color
    call draw_large_text
    
    ; Draw loading bar background (gray border)
    mov eax, 60         ; x position
    mov ebx, 100        ; y position
    mov ecx, 200        ; width
    mov edx, 20         ; height
    mov esi, 0x08       ; dark gray color
    call draw_filled_rectangle
    
    ; Animate loading bar (5 seconds total, 100 steps)
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
    
    ; 5 second delay: 100 steps * 50ms = 5 seconds
    push ebx
    mov ecx, 0x80000    ; ~50ms delay per step
.delay_loop:
    loop .delay_loop
    pop ebx
    
    add ebx, 2          ; increase progress by 2 pixels
    jmp .loading_loop
    
.loading_done:
    ; Show "Complete!" message
    mov eax, 85         ; x position
    mov ebx, 130        ; y position
    mov esi, complete_message
    mov edi, 0x0A       ; bright green color
    call draw_large_text
    
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

; Draw large text (2x scale for better readability)
; EAX = x, EBX = y, ESI = text pointer, EDI = color
draw_large_text:
    push eax
    push ebx
    
.char_loop:
    mov cl, [esi]       ; Load character
    cmp cl, 0           ; Check for null terminator
    je .done
    
    ; Draw character at 2x scale
    push esi
    push edi
    movzx ecx, cl       ; Character code
    call draw_large_char
    pop edi
    pop esi
    
    add eax, 16         ; Move to next character position (16 pixels for 2x scale)
    inc esi             ; Next character
    jmp .char_loop
    
.done:
    pop ebx
    pop eax
    ret

; Draw regular text
; EAX = x, EBX = y, ESI = text pointer, EDI = color
draw_text:
    push eax
    push ebx
    
.char_loop:
    mov cl, [esi]       ; Load character
    cmp cl, 0           ; Check for null terminator
    je .done
    
    ; Draw character
    push esi
    push edi
    movzx ecx, cl       ; Character code
    call draw_char
    pop edi
    pop esi
    
    add eax, 8          ; Move to next character position (8 pixels)
    inc esi             ; Next character
    jmp .char_loop
    
.done:
    pop ebx
    pop eax
    ret

; Draw a single character at 2x scale (16x16)
; EAX = x, EBX = y, ECX = character code, EDI = color
draw_large_char:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    
    ; Get font data for character
    mov esi, font_data
    imul ecx, 8         ; Each char is 8 bytes
    add esi, ecx        ; Point to character data
    
    ; Draw 8 rows, each scaled to 2x2 pixels
    mov edx, 0          ; Row counter
.row_loop:
    cmp edx, 8
    jge .char_done
    
    mov cl, [esi + edx] ; Get row bitmap
    
    ; Draw this row twice (for 2x vertical scaling)
    push eax            ; Save original x
    push ebx            ; Save original y
    
    ; First row
    call .draw_scaled_row
    inc ebx             ; Move to next y
    ; Second row (duplicate)
    call .draw_scaled_row
    
    pop ebx             ; Restore y
    add ebx, 2          ; Move to next row (2 pixels down)
    pop eax             ; Restore x
    inc edx             ; Next row
    jmp .row_loop
    
.draw_scaled_row:
    push eax            ; Save x
    push ecx
    mov ecx, 0          ; Pixel counter
.pixel_loop:
    cmp ecx, 8
    jge .row_done
    
    ; Check if pixel should be drawn
    push ecx
    mov ch, 7
    sub ch, cl          ; Reverse bit order
    push eax
    mov al, [esi + edx]
    shr al, ch
    and al, 1
    cmp al, 1
    pop eax
    pop ecx
    jne .skip_pixel
    
    ; Draw 2x1 pixel block
    push ecx
    push edx
    push esi
    mov ecx, 2          ; width (2x scale)
    mov edx, 1          ; height
    mov esi, edi        ; color
    call draw_filled_rectangle
    pop esi
    pop edx
    pop ecx
    
.skip_pixel:
    add eax, 2          ; Next pixel x (2x scale)
    inc ecx             ; Next pixel
    jmp .pixel_loop
    
.row_done:
    pop ecx
    pop eax             ; Restore x
    ret
    
.char_done:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Draw normal character (8x8)
; EAX = x, EBX = y, ECX = character code, EDI = color
draw_char:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    
    ; Get font data for character
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
    
    ; Check if pixel should be drawn
    push ecx
    mov ch, 7
    sub ch, cl          ; Reverse bit order
    push eax
    mov al, [esi + edx]
    shr al, ch
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

; Simple 8x8 bitmap font data
font_data:
    ; Character 0x00-0x1F (control chars) - all blank
    times 32*8 db 0x00
    
    ; 0x20 - Space
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    ; 0x21 - !
    db 0x18, 0x18, 0x18, 0x18, 0x18, 0x00, 0x18, 0x00
    ; 0x22-0x2F - Various symbols (simplified)
    times 14*8 db 0x00
    
    ; 0x30-0x39 - Numbers
    db 0x3C, 0x66, 0x6E, 0x76, 0x66, 0x66, 0x3C, 0x00  ; 0
    db 0x18, 0x38, 0x18, 0x18, 0x18, 0x18, 0x7E, 0x00  ; 1
    db 0x3C, 0x66, 0x06, 0x0C, 0x18, 0x30, 0x7E, 0x00  ; 2
    db 0x3C, 0x66, 0x06, 0x1C, 0x06, 0x66, 0x3C, 0x00  ; 3
    db 0x0C, 0x1C, 0x3C, 0x6C, 0x7E, 0x0C, 0x0C, 0x00  ; 4
    db 0x7E, 0x60, 0x7C, 0x06, 0x06, 0x66, 0x3C, 0x00  ; 5
    db 0x3C, 0x60, 0x7C, 0x66, 0x66, 0x66, 0x3C, 0x00  ; 6
    db 0x7E, 0x06, 0x0C, 0x18, 0x30, 0x30, 0x30, 0x00  ; 7
    db 0x3C, 0x66, 0x66, 0x3C, 0x66, 0x66, 0x3C, 0x00  ; 8
    db 0x3C, 0x66, 0x66, 0x3E, 0x06, 0x0C, 0x38, 0x00  ; 9
    
    ; 0x3A-0x40 - Symbols
    times 7*8 db 0x00
    
    ; 0x41-0x5A - Letters A-Z
    db 0x18, 0x3C, 0x66, 0x66, 0x7E, 0x66, 0x66, 0x00  ; A
    db 0x7C, 0x66, 0x66, 0x7C, 0x66, 0x66, 0x7C, 0x00  ; B
    db 0x3C, 0x66, 0x60, 0x60, 0x60, 0x66, 0x3C, 0x00  ; C
    db 0x78, 0x6C, 0x66, 0x66, 0x66, 0x6C, 0x78, 0x00  ; D
    db 0x7E, 0x60, 0x60, 0x7C, 0x60, 0x60, 0x7E, 0x00  ; E
    db 0x7E, 0x60, 0x60, 0x7C, 0x60, 0x60, 0x60, 0x00  ; F
    db 0x3C, 0x66, 0x60, 0x6E, 0x66, 0x66, 0x3C, 0x00  ; G
    db 0x66, 0x66, 0x66, 0x7E, 0x66, 0x66, 0x66, 0x00  ; H
    db 0x7E, 0x18, 0x18, 0x18, 0x18, 0x18, 0x7E, 0x00  ; I
    db 0x1E, 0x0C, 0x0C, 0x0C, 0x0C, 0x6C, 0x38, 0x00  ; J
    db 0x66, 0x6C, 0x78, 0x70, 0x78, 0x6C, 0x66, 0x00  ; K
    db 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x7E, 0x00  ; L
    db 0x63, 0x77, 0x7F, 0x6B, 0x63, 0x63, 0x63, 0x00  ; M
    db 0x66, 0x76, 0x7E, 0x7E, 0x6E, 0x66, 0x66, 0x00  ; N
    db 0x3C, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x00  ; O
    db 0x7C, 0x66, 0x66, 0x7C, 0x60, 0x60, 0x60, 0x00  ; P
    db 0x3C, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x0E, 0x00  ; Q
    db 0x7C, 0x66, 0x66, 0x7C, 0x78, 0x6C, 0x66, 0x00  ; R
    db 0x3C, 0x66, 0x60, 0x3C, 0x06, 0x66, 0x3C, 0x00  ; S
    db 0x7E, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00  ; T
    db 0x66, 0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x00  ; U
    db 0x66, 0x66, 0x66, 0x66, 0x66, 0x3C, 0x18, 0x00  ; V
    db 0x63, 0x63, 0x63, 0x6B, 0x7F, 0x77, 0x63, 0x00  ; W
    db 0x66, 0x66, 0x3C, 0x18, 0x3C, 0x66, 0x66, 0x00  ; X
    db 0x66, 0x66, 0x66, 0x3C, 0x18, 0x18, 0x18, 0x00  ; Y
    db 0x7E, 0x06, 0x0C, 0x18, 0x30, 0x60, 0x7E, 0x00  ; Z
    
    ; Fill remaining characters with blanks
    times (256-91)*8 db 0x00

; Pad to ensure proper alignment
times 4096-($-$$) db 0
