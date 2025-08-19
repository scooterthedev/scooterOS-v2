[BITS 32]
[ORG 0x1000]

; Simple GUI-Enabled 32-bit Kernel Entry Point
_start:
    ; Set up stack
    mov esp, 0x90000

    ; Show loading screen IMMEDIATELY (before anything else)
    call show_loading_screen

    ; Show desktop and wait for input
    call show_main_gui
    call main_loop

    ; Fallback infinite loop (should never reach here)
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
    
    ; Draw CLI instruction
    mov eax, 20
    mov ebx, 65
    mov esi, cli_message
    mov edi, 0x04       ; red color for visibility
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

; Display memory information on desktop
display_memory_info:
    ; Check if memory system is initialized
    cmp dword [heap_start], 0
    je .skip_memory_display
    
    ; Get current memory stats
    call get_memory_stats
    mov [mem_allocated], eax
    mov [mem_count], ebx
    mov [mem_free], ecx
    
    ; Display memory info title
    mov eax, 200
    mov ebx, 20
    mov esi, memory_title
    mov edi, 0x00
    call draw_text
    
    ; Display allocated memory
    mov eax, 200
    mov ebx, 35
    mov esi, allocated_text
    mov edi, 0x00
    call draw_text
    
    ; Convert allocated bytes to string and display
    mov eax, [mem_allocated]
    call convert_number_to_string
    mov eax, 270
    mov ebx, 35
    mov esi, number_buffer
    mov edi, 0x00
    call draw_text
    
    ; Display allocation count
    mov eax, 200
    mov ebx, 50
    mov esi, count_text
    mov edi, 0x00
    call draw_text
    
    mov eax, [mem_count]
    call convert_number_to_string
    mov eax, 250
    mov ebx, 50
    mov esi, number_buffer
    mov edi, 0x00
    call draw_text
    
    ; Display free memory
    mov eax, 200
    mov ebx, 65
    mov esi, free_text
    mov edi, 0x00
    call draw_text
    
    mov eax, [mem_free]
    call convert_number_to_string
    mov eax, 240
    mov ebx, 65
    mov esi, number_buffer
    mov edi, 0x00
    call draw_text
    
    ; Display test instruction
    mov eax, 200
    mov ebx, 85
    mov esi, test_instruction
    mov edi, 0x04       ; red color
    call draw_text
    
.skip_memory_display:
    ret

; Convert a number to string (simple version for small numbers)
; Input: EAX = number
; Output: number_buffer contains ASCII string
convert_number_to_string:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Handle zero case
    test eax, eax
    jnz .not_zero
    mov byte [number_buffer], '0'
    mov byte [number_buffer+1], 0
    jmp .convert_done
    
.not_zero:
    mov edi, number_buffer + 8  ; Start from end of buffer (safer)
    mov byte [edi], 0           ; Null terminator
    dec edi
    
    mov ebx, 10                 ; Divisor
    
.convert_loop:
    xor edx, edx
    div ebx                     ; EAX = quotient, EDX = remainder
    add dl, '0'                 ; Convert to ASCII
    mov [edi], dl
    dec edi
    
    test eax, eax
    jnz .convert_loop
    
    ; Move string to start of buffer
    inc edi                     ; Point to first digit
    mov esi, edi
    mov edi, number_buffer
    
.copy_loop:
    mov al, [esi]
    mov [edi], al
    test al, al
    jz .convert_done
    inc esi
    inc edi
    jmp .copy_loop
    
.convert_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
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

; Main event loop
main_loop:
    ; Skip mouse cursor for now - we'll implement simple keyboard input
    
.input_loop:
    ; Check for keyboard input
    in al, 0x60         ; Read keyboard scan code
    
    ; Debug: Show scan code
    push eax
    mov eax, 250
    mov ebx, 10
    mov esi, scan_debug_msg
    mov edx, 0x0C       ; red text
    call draw_text
    pop eax
    
    ; Check for F key (0x21) or Space (0x39) to open CLI
    cmp al, 0x21        ; F key
    je activate_cli
    cmp al, 0x39        ; Space key  
    je activate_cli
    
    ; Check for ESC key (0x01) to exit
    cmp al, 0x01
    je infinite_loop
    
    ; Small delay and loop
    mov ecx, 10000
.delay:
    nop
    loop .delay
    jmp .input_loop

; Activate CLI interface
activate_cli:
    ; Wait for key release first
    call wait_key_release
    
    ; Clear screen to black
    mov edi, 0xA0000
    mov ecx, 64000
    mov al, 0x00        ; Black background
    rep stosb
    
    ; Draw simple CLI window
    mov eax, 20         ; x
    mov ebx, 20         ; y  
    mov ecx, 280        ; width
    mov edx, 160        ; height
    mov esi, 0x01       ; blue background
    call draw_filled_rectangle
    
    ; Draw border
    mov eax, 19
    mov ebx, 19
    mov ecx, 282
    mov edx, 162
    mov esi, 0x0F       ; white border
    call draw_filled_rectangle
    
    ; Redraw inner area
    mov eax, 21
    mov ebx, 21
    mov ecx, 278
    mov edx, 158
    mov esi, 0x01       ; blue background
    call draw_filled_rectangle
    
    ; Show title
    mov eax, 30
    mov ebx, 35
    mov esi, cli_prompt
    mov edx, 0x0F       ; white text
    call draw_text
    
    ; Show simple instruction
    mov eax, 30
    mov ebx, 55
    mov esi, cli_help4  ; ESC to exit
    mov edx, 0x0E       ; yellow text
    call draw_text
    
    ; Wait for ESC to exit CLI
.cli_loop:
    in al, 0x60
    cmp al, 0x01        ; ESC key
    je .exit_cli
    
    ; Much longer delay to prevent issues
    mov ecx, 50000
.cli_delay:
    nop
    loop .cli_delay
    jmp .cli_loop
    
.exit_cli:
    call wait_key_release
    call show_main_gui  ; Return to desktop
    jmp main_loop

; Wait for key release (scan code with bit 7 set)
wait_key_release:
    push eax
.wait_loop:
    in al, 0x60
    test al, 0x80       ; Check if bit 7 is set (key release)
    jz .wait_loop       ; Keep waiting if not released
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

; Handle M key - test memory system
handle_memory_test:
    ; Wait for key release
    call wait_key_release
    
    ; Run memory test
    call test_memory_system
    
    ; Redraw GUI to show updated memory stats
    call show_main_gui
    
    jmp infinite_loop

; =====================================
; MEMORY MANAGEMENT SYSTEM
; =====================================

; Initialize memory management system
init_memory_manager:
    ; Set up heap starting at 0x100000 (1MB) - use safer smaller heap
    mov dword [heap_start], 0x100000
    mov dword [heap_current], 0x100000
    mov dword [heap_end], 0x180000      ; 512KB heap size (safer)
    mov dword [total_allocated], 0
    mov dword [allocation_count], 0
    
    ; Don't clear memory at boot - just set up pointers
    ; The heap will be initialized on first allocation
    
    ret

; Allocate memory block
; Input: EAX = size in bytes
; Output: EAX = pointer to allocated memory (0 if failed)
malloc:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Align size to 16 bytes
    add eax, 15
    and eax, 0xFFFFFFF0
    mov ebx, eax                        ; EBX = aligned size
    
    ; Add header size (16 bytes)
    add ebx, 16
    
    ; Find free block
    mov esi, [heap_start]
.find_block:
    cmp esi, [heap_current]
    jge .allocate_new
    
    ; Check if block is free (size = 0) and big enough
    mov eax, [esi]                      ; Get block size
    cmp eax, 0                          ; Is it free?
    jne .next_block
    
    ; Check if we have enough space from here to heap_current
    mov eax, [heap_current]
    sub eax, esi
    cmp eax, ebx
    jl .next_block
    
    ; Found suitable free block
    jmp .allocate_here
    
.next_block:
    ; Move to next block
    mov eax, [esi]                      ; Get block size
    add esi, eax                        ; Move to next block
    add esi, 16                         ; Add header size
    jmp .find_block
    
.allocate_new:
    ; Allocate at end of heap
    mov esi, [heap_current]
    
.allocate_here:
    ; Check if we have enough space in heap
    mov eax, esi
    add eax, ebx
    cmp eax, [heap_end]
    jg .allocation_failed
    
    ; Set up block header
    mov [esi], ebx                      ; Store total block size
    mov dword [esi + 4], 0xDEADBEEF     ; Magic number
    mov dword [esi + 8], ebx            ; Store requested size
    mov dword [esi + 12], 0             ; Reserved
    
    ; Update heap current if we allocated at the end
    cmp esi, [heap_current]
    jne .update_stats
    add [heap_current], ebx
    
.update_stats:
    ; Update allocation statistics
    add [total_allocated], ebx
    inc dword [allocation_count]
    
    ; Return pointer to usable memory (after header)
    mov eax, esi
    add eax, 16
    jmp .malloc_done
    
.allocation_failed:
    xor eax, eax                        ; Return NULL
    
.malloc_done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; Free memory block
; Input: EAX = pointer to memory block
free:
    push ebx
    push ecx
    push edx
    
    ; Check for NULL pointer
    test eax, eax
    jz .free_done
    
    ; Get block header (subtract 16 bytes)
    sub eax, 16
    mov ebx, eax
    
    ; Validate magic number
    cmp dword [ebx + 4], 0xDEADBEEF
    jne .free_done                      ; Invalid block
    
    ; Get block size
    mov ecx, [ebx]
    
    ; Mark block as free (set size to 0)
    mov dword [ebx], 0
    mov dword [ebx + 4], 0xFEEDFACE     ; Free magic number
    
    ; Update statistics
    sub [total_allocated], ecx
    dec dword [allocation_count]
    
.free_done:
    pop edx
    pop ecx
    pop ebx
    ret

; Get memory statistics
; Output: EAX = total allocated, EBX = allocation count, ECX = free space
get_memory_stats:
    mov eax, [total_allocated]
    mov ebx, [allocation_count]
    mov ecx, [heap_end]
    sub ecx, [heap_current]             ; Free space = heap_end - heap_current
    ret

; Clear all allocated memory (reset heap)
reset_heap:
    mov eax, [heap_start]
    mov [heap_current], eax
    mov dword [total_allocated], 0
    mov dword [allocation_count], 0
    
    ; Clear the first block header
    mov edi, [heap_start]
    mov ecx, 16
    xor eax, eax
    rep stosb
    ret

; Memory test function - allocate and free some blocks
test_memory_system:
    push eax
    push ebx
    push ecx
    
    ; Allocate 100 bytes
    mov eax, 100
    call malloc
    mov [test_ptr1], eax
    
    ; Allocate 200 bytes
    mov eax, 200
    call malloc
    mov [test_ptr2], eax
    
    ; Allocate 50 bytes
    mov eax, 50
    call malloc
    mov [test_ptr3], eax
    
    ; Free middle block
    mov eax, [test_ptr2]
    call free
    
    ; Get stats for display
    call get_memory_stats
    mov [mem_allocated], eax
    mov [mem_count], ebx
    mov [mem_free], ecx
    
    pop ecx
    pop ebx
    pop eax
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
cli_message db 'Press SPACEBAR for CLI', 0
start_text db 'Start', 0
clock_text db '12:00', 0
selection_msg db 'Selected: ', 0
app_placeholder_msg db 'App slot clicked: ', 0
start_menu_msg db 'Start menu opened!', 0
computer_icon_text db 'Computer', 0
folder_icon_text db 'Folder', 0

; CLI interface strings
cli_prompt db 'ScooterOS Command Line Interface', 0
cli_help1 db 'Available Commands:', 0
cli_help2 db '  help - Show this help', 0
cli_help3 db '  ls   - List files', 0
cli_help4 db '  ESC  - Exit CLI', 0

; Debug message
scan_debug_msg db 'Key detected!', 0

; Memory management strings
memory_title db 'Memory Info:', 0
allocated_text db 'Alloc:', 0
count_text db 'Count:', 0
free_text db 'Free:', 0
test_instruction db 'Press M to test', 0
number_buffer db '0000000000', 0    ; Buffer for number conversion

; Navigation state
selected_button db 0        ; 0=Start, 1-4=App slots
temp_char db 0, 0          ; Temporary character storage

; Memory Management Variables
heap_start dd 0             ; Start of heap
heap_current dd 0           ; Current end of heap
heap_end dd 0               ; End of heap
total_allocated dd 0        ; Total allocated memory
allocation_count dd 0       ; Number of allocations
test_ptr1 dd 0              ; Test pointers
test_ptr2 dd 0
test_ptr3 dd 0
mem_allocated dd 0          ; Memory stats for display
mem_count dd 0
mem_free dd 0

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

; =====================================
; ASSEMBLY HELPER FUNCTIONS FOR C CODE
; =====================================

; Export functions for C code
global asm_clear_screen
global asm_draw_pixel
global asm_get_keyboard
global asm_delay

; Clear screen to specified color
; void asm_clear_screen(unsigned char color)
asm_clear_screen:
    push ebp
    mov ebp, esp
    push edi
    push eax
    push ecx
    
    mov al, [ebp + 8]       ; Get color parameter
    mov edi, 0xA0000        ; VGA memory
    mov ecx, 64000          ; 320x200 pixels
    rep stosb               ; Fill screen with color
    
    pop ecx
    pop eax
    pop edi
    pop ebp
    ret

; Draw a single pixel
; void asm_draw_pixel(int x, int y, unsigned char color)
asm_draw_pixel:
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push edx
    
    mov eax, [ebp + 8]      ; x
    mov ebx, [ebp + 12]     ; y
    mov dl, [ebp + 16]      ; color
    
    ; Bounds check
    cmp eax, 0
    jl .done
    cmp eax, 320
    jge .done
    cmp ebx, 0
    jl .done
    cmp ebx, 200
    jge .done
    
    ; Calculate offset: y * 320 + x
    push eax
    mov eax, ebx
    mov ebx, 320
    mul ebx
    pop ebx
    add eax, ebx
    add eax, 0xA0000
    
    ; Set pixel
    mov [eax], dl
    
.done:
    pop edx
    pop ebx
    pop eax
    pop ebp
    ret

; Get keyboard scan code
; unsigned char asm_get_keyboard(void)
asm_get_keyboard:
    push ebp
    mov ebp, esp
    
    in al, 0x60     ; Read keyboard port
    movzx eax, al   ; Zero extend to 32-bit
    
    pop ebp
    ret

; Simple delay function
; void asm_delay(unsigned int count)
asm_delay:
    push ebp
    mov ebp, esp
    push ecx
    
    mov ecx, [ebp + 8]  ; Get count parameter
.delay_loop:
    loop .delay_loop
    
    pop ecx
    pop ebp
    ret

; Pad to ensure proper alignment
times 4096-($-$$) db 0
