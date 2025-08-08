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
    ; Clear entire screen to desktop color first
    mov edi, 0xA0000    ; VGA graphics buffer
    mov ecx, 64000      ; 320x200 pixels
    mov al, 0x03        ; Cyan desktop background
    rep stosb
    
    ; Draw taskbar
    call draw_taskbar
    
    ; Draw desktop title with better positioning
    mov eax, 20         ; x position
    mov ebx, 20         ; y position
    mov esi, desktop_message
    mov edi, 0x00       ; black color for better visibility
    call draw_text
    
    ; Draw navigation instructions with better spacing
    mov eax, 20
    mov ebx, 35
    mov esi, nav_message1
    mov edi, 0x00       ; black color
    call draw_text
    
    mov eax, 20
    mov ebx, 50
    mov esi, nav_message2
    mov edi, 0x00       ; black color
    call draw_text
    
    ; Draw some desktop icons as placeholders
    call draw_desktop_icons
    
    ret

; Draw desktop icons
draw_desktop_icons:
    ; Draw a "My Computer" icon
    mov eax, 40         ; x
    mov ebx, 80         ; y
    mov ecx, 32         ; width
    mov edx, 32         ; height
    mov esi, 0x07       ; light gray
    call draw_filled_rectangle
    
    ; Icon border
    mov eax, 40
    mov ebx, 80
    mov ecx, 32
    mov edx, 1
    mov esi, 0x00       ; black border
    call draw_filled_rectangle
    
    mov eax, 40
    mov ebx, 111
    mov ecx, 32
    mov edx, 1
    mov esi, 0x00
    call draw_filled_rectangle
    
    mov eax, 40
    mov ebx, 80
    mov ecx, 1
    mov edx, 32
    mov esi, 0x00
    call draw_filled_rectangle
    
    mov eax, 71
    mov ebx, 80
    mov ecx, 1
    mov edx, 32
    mov esi, 0x00
    call draw_filled_rectangle
    
    ; Icon label
    mov eax, 35
    mov ebx, 120
    mov esi, computer_icon_text
    mov edi, 0x00
    call draw_text
    
    ; Draw a "Folder" icon
    mov eax, 120        ; x
    mov ebx, 80         ; y
    mov ecx, 32         ; width
    mov edx, 32         ; height
    mov esi, 0x0E       ; yellow folder
    call draw_filled_rectangle
    
    ; Folder icon borders
    mov eax, 120
    mov ebx, 80
    mov ecx, 32
    mov edx, 1
    mov esi, 0x00
    call draw_filled_rectangle
    
    mov eax, 120
    mov ebx, 111
    mov ecx, 32
    mov edx, 1
    mov esi, 0x00
    call draw_filled_rectangle
    
    mov eax, 120
    mov ebx, 80
    mov ecx, 1
    mov edx, 32
    mov esi, 0x00
    call draw_filled_rectangle
    
    mov eax, 151
    mov ebx, 80
    mov ecx, 1
    mov edx, 32
    mov esi, 0x00
    call draw_filled_rectangle
    
    ; Folder label
    mov eax, 120
    mov ebx, 120
    mov esi, folder_icon_text
    mov edi, 0x00
    call draw_text
    
    ret

; Draw taskbar at bottom of screen
draw_taskbar:
    ; Draw taskbar background (dark gray)
    mov eax, 0          ; x
    mov ebx, 175        ; y (bottom 25 pixels)
    mov ecx, 320        ; width (full screen)
    mov edx, 25         ; height
    mov esi, 0x08       ; dark gray color
    call draw_filled_rectangle
    
    ; Draw taskbar top border (raised effect)
    mov eax, 0          ; x
    mov ebx, 175        ; y
    mov ecx, 320        ; width
    mov edx, 1          ; height (1 pixel line)
    mov esi, 0x0F       ; white color for raised effect
    call draw_filled_rectangle
    
    ; Draw taskbar bottom border
    mov eax, 0          ; x
    mov ebx, 199        ; y (bottom line)
    mov ecx, 320        ; width
    mov edx, 1          ; height
    mov esi, 0x00       ; black color
    call draw_filled_rectangle
    
    ; Draw Start button
    mov eax, 3          ; x
    mov ebx, 178        ; y
    mov ecx, 50         ; width
    mov edx, 19         ; height
    call draw_taskbar_button
    
    ; Draw Start text
    mov eax, 13         ; x position (centered)
    mov ebx, 185        ; y position
    mov esi, start_text
    mov edi, 0x00       ; black color for better contrast
    call draw_text
    
    ; Draw separator line after Start button
    mov eax, 56         ; x
    mov ebx, 178        ; y
    mov ecx, 1          ; width
    mov edx, 19         ; height
    mov esi, 0x00       ; black separator
    call draw_filled_rectangle
    
    ; Draw app slots (placeholder buttons for future apps)
    mov eax, 60         ; x start position
    mov ebx, 0          ; button counter
.draw_app_slots:
    cmp ebx, 4          ; Draw 4 app slots
    jge .slots_done
    
    push eax
    push ebx
    
    ; Calculate button position
    push eax
    mov eax, ebx
    mov ecx, 60         ; button width + spacing
    mul ecx
    pop ecx
    add eax, ecx        ; final x position
    
    ; Draw app button
    mov ebx, 178        ; y
    mov ecx, 55         ; width
    mov edx, 19         ; height
    call draw_taskbar_app_button
    
    ; Draw app slot number
    push eax
    push ebx
    add eax, 25         ; center text in button
    mov ebx, 185
    mov cl, [esp+4]     ; get original button counter
    add cl, '1'         ; convert to 1-4
    mov [temp_char], cl
    mov byte [temp_char+1], 0
    mov esi, temp_char
    mov edi, 0x07       ; light gray text
    call draw_text
    pop ebx
    pop eax
    
    pop ebx
    pop eax
    inc ebx
    jmp .draw_app_slots
    
.slots_done:
    ; Draw clock area with border
    mov eax, 265        ; x
    mov ebx, 178        ; y
    mov ecx, 50         ; width
    mov edx, 19         ; height
    mov esi, 0x07       ; light gray for clock
    call draw_filled_rectangle
    
    ; Clock border
    mov eax, 265
    mov ebx, 178
    mov ecx, 50
    mov edx, 1
    mov esi, 0x00       ; black top border
    call draw_filled_rectangle
    
    mov eax, 265
    mov ebx, 196
    mov ecx, 50
    mov edx, 1
    mov esi, 0x0F       ; white bottom border
    call draw_filled_rectangle
    
    ; Draw clock text
    mov eax, 275        ; x position (centered)
    mov ebx, 185        ; y position
    mov esi, clock_text
    mov edi, 0x00       ; black color
    call draw_text
    
    ret

; Draw a taskbar button (Start button style)
; EAX = x, EBX = y, ECX = width, EDX = height
draw_taskbar_button:
    push eax
    push ebx
    push ecx
    push edx
    
    ; Check if this is the selected button (Start is button 0)
    cmp byte [selected_button], 0
    je .draw_selected
    
    ; Draw normal button (raised effect)
    mov esi, 0x07       ; light gray
    call draw_filled_rectangle
    
    ; Draw highlight on top and left
    mov esi, 0x0F       ; white
    push ecx
    push edx
    mov ecx, [esp+12]   ; original width
    mov edx, 1          ; 1 pixel height
    call draw_filled_rectangle  ; top edge
    
    mov ecx, 1          ; 1 pixel width
    mov edx, [esp]      ; original height
    call draw_filled_rectangle  ; left edge
    pop edx
    pop ecx
    
    jmp .button_done
    
.draw_selected:
    ; Draw selected button (pressed effect)
    mov esi, 0x08       ; darker gray
    call draw_filled_rectangle
    
    ; Draw shadow on top and left
    mov esi, 0x00       ; black
    push ecx
    push edx
    mov ecx, [esp+12]   ; original width
    mov edx, 1          ; 1 pixel height
    call draw_filled_rectangle  ; top edge
    
    mov ecx, 1          ; 1 pixel width
    mov edx, [esp]      ; original height
    call draw_filled_rectangle  ; left edge
    pop edx
    pop ecx
    
.button_done:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Draw a taskbar app button slot
; EAX = x, EBX = y, ECX = width, EDX = height
draw_taskbar_app_button:
    push eax
    push ebx
    push ecx
    push edx
    push esi
    
    ; Calculate which app button this is (1-4)
    mov esi, eax
    sub esi, 60         ; subtract start position
    push edx
    mov edx, 0
    mov ecx, 60         ; button spacing
    div ecx             ; EAX = button number
    inc eax             ; buttons are 1-4, not 0-3
    pop edx
    
    ; Check if this is the selected button
    cmp al, [selected_button]
    je .draw_app_selected
    
    ; Draw normal app slot (slightly depressed)
    mov esi, 0x08       ; dark gray
    call draw_filled_rectangle
    jmp .app_done
    
.draw_app_selected:
    ; Draw selected app slot (highlighted)
    mov esi, 0x0B       ; cyan
    call draw_filled_rectangle
    
.app_done:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
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

; Enhanced infinite loop with taskbar navigation
infinite_loop:
    ; Check for keyboard input
    in al, 0x60         ; Read keyboard scan code
    
    ; Check for Tab key (0x0F) - navigate between taskbar items
    cmp al, 0x0F
    je handle_tab_key
    
    ; Check for Enter key (0x1C) - activate selected item
    cmp al, 0x1C
    je handle_enter_key
    
    ; Check for ESC key to reboot
    cmp al, 0x01        ; ESC key scan code
    je reboot_system
    
    ; Small delay
    mov ecx, 0x10000
.delay:
    loop .delay
    
    jmp infinite_loop

; Handle Tab key - cycle through taskbar items
handle_tab_key:
    ; Wait for key release to avoid multiple triggers
    call wait_key_release
    
    ; Increment selected button (0=Start, 1-4=Apps)
    inc byte [selected_button]
    cmp byte [selected_button], 5
    jl .tab_redraw
    mov byte [selected_button], 0  ; wrap to start
    
.tab_redraw:
    ; Clear feedback area first
    mov eax, 10
    mov ebx, 55
    mov ecx, 200
    mov edx, 30
    mov esi, 0x03       ; cyan to match desktop
    call draw_filled_rectangle
    
    ; Redraw taskbar to show new selection
    call draw_taskbar
    
    ; Show which item is selected
    mov eax, 10
    mov ebx, 55
    mov esi, selection_msg
    mov edi, 0x00       ; black color
    call draw_text
    
    ; Draw selected button number
    mov eax, 150
    mov ebx, 55
    mov cl, [selected_button]
    add cl, '0'        ; convert to ASCII
    mov [temp_char], cl
    mov byte [temp_char+1], 0
    mov esi, temp_char
    mov edi, 0x00       ; black color
    call draw_text
    
    jmp infinite_loop

; Handle Enter key - activate selected taskbar item
handle_enter_key:
    ; Wait for key release
    call wait_key_release
    
    ; Clear feedback area
    mov eax, 10
    mov ebx, 70
    mov ecx, 250
    mov edx, 15
    mov esi, 0x03       ; cyan to match desktop
    call draw_filled_rectangle
    
    ; Check which button is selected
    mov al, [selected_button]
    
    cmp al, 0
    je activate_start
    
    ; For app buttons (1-4), show placeholder message
    mov eax, 10
    mov ebx, 70
    mov esi, app_placeholder_msg
    mov edi, 0x00       ; black color
    call draw_text
    
    ; Show which app slot was clicked
    mov eax, 200
    mov ebx, 70
    mov cl, [selected_button]
    add cl, '0'
    mov [temp_char], cl
    mov byte [temp_char+1], 0
    mov esi, temp_char
    mov edi, 0x00       ; black color
    call draw_text
    
    jmp infinite_loop

activate_start:
    ; Show start menu placeholder
    mov eax, 10
    mov ebx, 70
    mov esi, start_menu_msg
    mov edi, 0x00       ; black color
    call draw_text
    
    jmp infinite_loop

; Wait for key release (scan code with bit 7 set)
wait_key_release:
.wait_loop:
    in al, 0x60
    test al, 0x80       ; Check if release code (bit 7 set)
    jz .wait_loop       ; Keep waiting if still pressed
    ret

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

; Desktop and taskbar messages
desktop_message db 'ScooterOS Desktop', 0
nav_message1 db 'Use TAB to navigate taskbar', 0
nav_message2 db 'Use ENTER to select items', 0
start_text db 'Start', 0
clock_text db '12:00', 0
selection_msg db 'Selected: ', 0
app_placeholder_msg db 'App slot clicked: ', 0
start_menu_msg db 'Start menu opened!', 0
computer_icon_text db 'Computer', 0
folder_icon_text db 'Folder', 0

; Navigation state
selected_button db 0        ; 0=Start, 1-4=App slots
temp_char db 0, 0          ; Temporary character storage

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
