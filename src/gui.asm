; gui.asm - Advanced GUI System
[BITS 32]

; Advanced GUI system with windows, buttons, and mouse interaction

; GUI Constants
SCREEN_WIDTH    equ 320
SCREEN_HEIGHT   equ 200
VGA_BUFFER      equ 0xA0000

; Color definitions
COLOR_BLACK     equ 0x00
COLOR_BLUE      equ 0x01
COLOR_GREEN     equ 0x02
COLOR_CYAN      equ 0x03
COLOR_RED       equ 0x04
COLOR_MAGENTA   equ 0x05
COLOR_BROWN     equ 0x06
COLOR_LGRAY     equ 0x07
COLOR_DGRAY     equ 0x08
COLOR_LBLUE     equ 0x09
COLOR_LGREEN    equ 0x0A
COLOR_LCYAN     equ 0x0B
COLOR_LRED      equ 0x0C
COLOR_LMAGENTA  equ 0x0D
COLOR_YELLOW    equ 0x0E
COLOR_WHITE     equ 0x0F

; Window structure
struc Window
    .x          resd 1      ; X position
    .y          resd 1      ; Y position
    .width      resd 1      ; Width
    .height     resd 1      ; Height
    .title      resd 1      ; Pointer to title string
    .bg_color   resb 1      ; Background color
    .border_color resb 1    ; Border color
    .active     resb 1      ; Is window active
    .visible    resb 1      ; Is window visible
endstruc

; Button structure
struc Button
    .x          resd 1      ; X position
    .y          resd 1      ; Y position
    .width      resd 1      ; Width
    .height     resd 1      ; Height
    .text       resd 1      ; Pointer to button text
    .bg_color   resb 1      ; Background color
    .text_color resb 1      ; Text color
    .pressed    resb 1      ; Is button pressed
    .enabled    resb 1      ; Is button enabled
endstruc

; Initialize GUI system
init_gui:
    pusha
    
    ; Set VGA mode 13h (320x200x256)
    mov ah, 0x00
    mov al, 0x13
    int 0x10
    
    ; Clear screen
    call clear_screen
    
    ; Initialize windows
    call init_windows
    
    ; Initialize buttons
    call init_buttons
    
    ; Draw desktop
    call draw_desktop
    
    popa
    ret

; Clear screen with background color
clear_screen:
    pusha
    
    mov edi, VGA_BUFFER
    mov ecx, SCREEN_WIDTH * SCREEN_HEIGHT
    mov al, COLOR_CYAN      ; Desktop background
    rep stosb
    
    popa
    ret

; Draw desktop background with pattern
draw_desktop:
    pusha
    
    ; Draw desktop background with gradient effect
    mov ebx, 0              ; Y counter
.y_loop:
    cmp ebx, SCREEN_HEIGHT
    jge .done
    
    mov eax, 0              ; X counter
.x_loop:
    cmp eax, SCREEN_WIDTH
    jge .next_y
    
    ; Calculate pixel position
    mov edi, ebx
    imul edi, SCREEN_WIDTH
    add edi, eax
    add edi, VGA_BUFFER
    
    ; Create gradient effect
    mov ecx, ebx
    shr ecx, 3              ; Divide by 8 for color gradient
    add ecx, COLOR_BLUE
    cmp ecx, COLOR_CYAN
    jle .set_pixel
    mov ecx, COLOR_CYAN
    
.set_pixel:
    mov [edi], cl
    
    inc eax
    jmp .x_loop
    
.next_y:
    inc ebx
    jmp .y_loop
    
.done:
    ; Draw taskbar
    call draw_taskbar
    
    popa
    ret

; Draw taskbar at bottom of screen
draw_taskbar:
    pusha
    
    mov eax, 0              ; X start
    mov ebx, 180            ; Y start (bottom 20 pixels)
    mov ecx, SCREEN_WIDTH   ; Width
    mov edx, 20             ; Height
    mov esi, COLOR_DGRAY    ; Color
    call draw_filled_rect
    
    ; Draw taskbar border
    mov eax, 0
    mov ebx, 180
    mov ecx, SCREEN_WIDTH
    mov edx, 20
    mov esi, COLOR_WHITE
    call draw_rect_border
    
    ; Draw clock area
    mov eax, 250            ; X position
    mov ebx, 185            ; Y position
    mov esi, clock_text
    mov edi, COLOR_WHITE
    call draw_text_simple
    
    popa
    ret

; Initialize main window
init_windows:
    pusha
    
    ; Main window
    mov dword [main_window + Window.x], 50
    mov dword [main_window + Window.y], 30
    mov dword [main_window + Window.width], 220
    mov dword [main_window + Window.height], 120
    mov dword [main_window + Window.title], window_title
    mov byte [main_window + Window.bg_color], COLOR_LGRAY
    mov byte [main_window + Window.border_color], COLOR_DGRAY
    mov byte [main_window + Window.active], 1
    mov byte [main_window + Window.visible], 1
    
    popa
    ret

; Initialize buttons
init_buttons:
    pusha
    
    ; Button 1
    mov dword [button1 + Button.x], 70
    mov dword [button1 + Button.y], 70
    mov dword [button1 + Button.width], 50
    mov dword [button1 + Button.height], 20
    mov dword [button1 + Button.text], button1_text
    mov byte [button1 + Button.bg_color], COLOR_LGREEN
    mov byte [button1 + Button.text_color], COLOR_BLACK
    mov byte [button1 + Button.pressed], 0
    mov byte [button1 + Button.enabled], 1
    
    ; Button 2
    mov dword [button2 + Button.x], 140
    mov dword [button2 + Button.y], 70
    mov dword [button2 + Button.width], 50
    mov dword [button2 + Button.height], 20
    mov dword [button2 + Button.text], button2_text
    mov byte [button2 + Button.bg_color], COLOR_LRED
    mov byte [button2 + Button.text_color], COLOR_BLACK
    mov byte [button2 + Button.pressed], 0
    mov byte [button2 + Button.enabled], 1
    
    ; Button 3 (Close button)
    mov dword [button3 + Button.x], 240
    mov dword [button3 + Button.y], 35
    mov dword [button3 + Button.width], 25
    mov dword [button3 + Button.height], 15
    mov dword [button3 + Button.text], button3_text
    mov byte [button3 + Button.bg_color], COLOR_RED
    mov byte [button3 + Button.text_color], COLOR_WHITE
    mov byte [button3 + Button.pressed], 0
    mov byte [button3 + Button.enabled], 1
    
    popa
    ret

; Draw window
; Input: ESI = pointer to Window structure
draw_window:
    pusha
    
    ; Check if window is visible
    cmp byte [esi + Window.visible], 0
    je .done
    
    ; Draw window background
    mov eax, [esi + Window.x]
    mov ebx, [esi + Window.y]
    mov ecx, [esi + Window.width]
    mov edx, [esi + Window.height]
    movzx edi, byte [esi + Window.bg_color]
    push esi
    mov esi, edi
    call draw_filled_rect
    pop esi
    
    ; Draw window border
    mov eax, [esi + Window.x]
    mov ebx, [esi + Window.y]
    mov ecx, [esi + Window.width]
    mov edx, [esi + Window.height]
    movzx edi, byte [esi + Window.border_color]
    push esi
    mov esi, edi
    call draw_rect_border
    pop esi
    
    ; Draw title bar
    mov eax, [esi + Window.x]
    add eax, 2
    mov ebx, [esi + Window.y]
    add ebx, 2
    mov ecx, [esi + Window.width]
    sub ecx, 4
    mov edx, 16
    push esi
    mov esi, COLOR_BLUE
    call draw_filled_rect
    pop esi
    
    ; Draw title text
    mov eax, [esi + Window.x]
    add eax, 8
    mov ebx, [esi + Window.y]
    add ebx, 6
    mov edi, [esi + Window.title]
    push esi
    mov esi, edi
    mov edi, COLOR_WHITE
    call draw_text_simple
    pop esi
    
.done:
    popa
    ret

; Draw button
; Input: ESI = pointer to Button structure
draw_button:
    pusha
    
    ; Check if button is enabled
    cmp byte [esi + Button.enabled], 0
    je .done
    
    ; Choose color based on pressed state
    movzx edi, byte [esi + Button.bg_color]
    cmp byte [esi + Button.pressed], 0
    je .not_pressed
    
    ; Button is pressed - darker color
    cmp edi, COLOR_LGREEN
    jne .check_red
    mov edi, COLOR_GREEN
    jmp .draw_bg
    
.check_red:
    cmp edi, COLOR_LRED
    jne .draw_bg
    mov edi, COLOR_RED
    
.not_pressed:
.draw_bg:
    ; Draw button background
    mov eax, [esi + Button.x]
    mov ebx, [esi + Button.y]
    mov ecx, [esi + Button.width]
    mov edx, [esi + Button.height]
    push esi
    mov esi, edi
    call draw_filled_rect
    pop esi
    
    ; Draw button border
    mov eax, [esi + Button.x]
    mov ebx, [esi + Button.y]
    mov ecx, [esi + Button.width]
    mov edx, [esi + Button.height]
    push esi
    mov esi, COLOR_BLACK
    call draw_rect_border
    pop esi
    
    ; Draw button text (centered)
    mov eax, [esi + Button.x]
    add eax, 8              ; Rough centering
    mov ebx, [esi + Button.y]
    add ebx, 6
    mov edi, [esi + Button.text]
    movzx ecx, byte [esi + Button.text_color]
    push esi
    mov esi, edi
    mov edi, ecx
    call draw_text_simple
    pop esi
    
.done:
    popa
    ret

; Draw filled rectangle
; Input: EAX=x, EBX=y, ECX=width, EDX=height, ESI=color
draw_filled_rect:
    pusha
    
    add edx, ebx            ; end_y = y + height
    
.y_loop:
    cmp ebx, edx
    jge .done
    
    push eax
    push edx
    add ecx, eax            ; end_x = x + width
    
.x_loop:
    cmp eax, ecx
    jge .next_y
    
    ; Bounds check
    cmp eax, 0
    jl .skip_pixel
    cmp eax, SCREEN_WIDTH
    jge .skip_pixel
    cmp ebx, 0
    jl .skip_pixel
    cmp ebx, SCREEN_HEIGHT
    jge .skip_pixel
    
    ; Calculate pixel offset
    push edx
    mov edi, ebx
    imul edi, SCREEN_WIDTH
    add edi, eax
    add edi, VGA_BUFFER
    mov [edi], sil
    pop edx
    
.skip_pixel:
    inc eax
    jmp .x_loop
    
.next_y:
    pop edx
    pop eax
    inc ebx
    jmp .y_loop
    
.done:
    popa
    ret

; Draw rectangle border
; Input: EAX=x, EBX=y, ECX=width, EDX=height, ESI=color
draw_rect_border:
    pusha
    
    ; Top line
    push edx
    mov edx, 1
    call draw_filled_rect
    pop edx
    
    ; Bottom line
    push eax
    push ebx
    add ebx, edx
    dec ebx
    mov edx, 1
    call draw_filled_rect
    pop ebx
    pop eax
    
    ; Left line
    push ecx
    mov ecx, 1
    call draw_filled_rect
    pop ecx
    
    ; Right line
    add eax, ecx
    dec eax
    mov ecx, 1
    call draw_filled_rect
    
    popa
    ret

; Simple text drawing (block characters)
; Input: EAX=x, EBX=y, ESI=text, EDI=color
draw_text_simple:
    pusha
    
.char_loop:
    mov cl, [esi]
    cmp cl, 0
    je .done
    
    ; Draw character as small filled rectangle
    push esi
    push edi
    mov ecx, 6              ; char width
    mov edx, 8              ; char height
    mov esi, edi            ; color
    call draw_filled_rect
    pop edi
    pop esi
    
    add eax, 7              ; Move to next char position
    inc esi
    jmp .char_loop
    
.done:
    popa
    ret

; Advanced cursor drawing with proper mouse cursor shape
draw_cursor:
    pusha
    
    ; Get mouse position
    call get_mouse_position ; Returns EAX=x, EBX=y
    
    ; Draw cursor shape (arrow)
    mov ecx, eax            ; Save X
    mov edx, ebx            ; Save Y
    
    ; Draw cursor outline (black)
    mov esi, COLOR_BLACK
    call draw_cursor_shape
    
    ; Draw cursor fill (white) - slightly offset
    inc ecx
    inc edx
    mov esi, COLOR_WHITE
    call draw_cursor_shape
    
    popa
    ret

; Draw cursor shape at ECX, EDX with color ESI
draw_cursor_shape:
    pusha
    
    ; Simple arrow cursor (vertical line + diagonal)
    mov eax, ecx
    mov ebx, edx
    mov ecx, 2
    mov edx, 12
    call draw_filled_rect
    
    ; Arrow head
    mov eax, [esp+16]       ; Original ECX
    add eax, 2
    mov ebx, [esp+12]       ; Original EDX
    add ebx, 8
    mov ecx, 6
    mov edx, 4
    call draw_filled_rect
    
    popa
    ret

; Refresh entire GUI
refresh_gui:
    pusha
    
    ; Redraw desktop
    call draw_desktop
    
    ; Draw main window
    mov esi, main_window
    call draw_window
    
    ; Draw all buttons
    mov esi, button1
    call draw_button
    
    mov esi, button2
    call draw_button
    
    mov esi, button3
    call draw_button
    
    ; Draw cursor last (on top)
    call draw_cursor
    
    popa
    ret

; Handle button click
; Input: EAX=mouse_x, EBX=mouse_y
handle_button_click:
    pusha
    
    ; Check button 1
    mov ecx, [button1 + Button.width]
    mov edx, [button1 + Button.height]
    push eax
    push ebx
    mov eax, [button1 + Button.x]
    mov ebx, [button1 + Button.y]
    call is_mouse_over_rect
    cmp al, 1
    jne .check_button2
    
    ; Button 1 clicked
    mov byte [button1 + Button.pressed], 1
    call button1_action
    jmp .done
    
.check_button2:
    pop ebx
    pop eax
    mov ecx, [button2 + Button.width]
    mov edx, [button2 + Button.height]
    push eax
    push ebx
    mov eax, [button2 + Button.x]
    mov ebx, [button2 + Button.y]
    call is_mouse_over_rect
    cmp al, 1
    jne .check_button3
    
    ; Button 2 clicked
    mov byte [button2 + Button.pressed], 1
    call button2_action
    jmp .done
    
.check_button3:
    pop ebx
    pop eax
    mov ecx, [button3 + Button.width]
    mov edx, [button3 + Button.height]
    mov eax, [button3 + Button.x]
    mov ebx, [button3 + Button.y]
    call is_mouse_over_rect
    cmp al, 1
    jne .done
    
    ; Button 3 (close) clicked
    call button3_action
    
.done:
    ; Clear button pressed states after a delay
    call small_delay
    mov byte [button1 + Button.pressed], 0
    mov byte [button2 + Button.pressed], 0
    
    add esp, 8              ; Clean up stack
    popa
    ret

; Button actions
button1_action:
    ; Change window background color
    mov al, [main_window + Window.bg_color]
    cmp al, COLOR_LGRAY
    je .set_yellow
    mov byte [main_window + Window.bg_color], COLOR_LGRAY
    ret
.set_yellow:
    mov byte [main_window + Window.bg_color], COLOR_YELLOW
    ret

button2_action:
    ; Toggle window title
    cmp dword [main_window + Window.title], window_title
    je .set_alt_title
    mov dword [main_window + Window.title], window_title
    ret
.set_alt_title:
    mov dword [main_window + Window.title], alt_title
    ret

button3_action:
    ; Close/minimize window effect
    mov byte [main_window + Window.visible], 0
    call small_delay
    mov byte [main_window + Window.visible], 1
    ret

; Small delay routine
small_delay:
    push ecx
    mov ecx, 0x100000
.delay_loop:
    loop .delay_loop
    pop ecx
    ret

; Data section
main_window:
    istruc Window
        at Window.x,            dd 50
        at Window.y,            dd 30
        at Window.width,        dd 220
        at Window.height,       dd 120
        at Window.title,        dd window_title
        at Window.bg_color,     db COLOR_LGRAY
        at Window.border_color, db COLOR_DGRAY
        at Window.active,       db 1
        at Window.visible,      db 1
    iend

button1:
    istruc Button
        at Button.x,            dd 70
        at Button.y,            dd 70
        at Button.width,        dd 50
        at Button.height,       dd 20
        at Button.text,         dd button1_text
        at Button.bg_color,     db COLOR_LGREEN
        at Button.text_color,   db COLOR_BLACK
        at Button.pressed,      db 0
        at Button.enabled,      db 1
    iend

button2:
    istruc Button
        at Button.x,            dd 140
        at Button.y,            dd 70
        at Button.width,        dd 50
        at Button.height,       dd 20
        at Button.text,         dd button2_text
        at Button.bg_color,     db COLOR_LRED
        at Button.text_color,   db COLOR_BLACK
        at Button.pressed,      db 0
        at Button.enabled,      db 1
    iend

button3:
    istruc Button
        at Button.x,            dd 240
        at Button.y,            dd 35
        at Button.width,        dd 25
        at Button.height,       dd 15
        at Button.text,         dd button3_text
        at Button.bg_color,     db COLOR_RED
        at Button.text_color,   db COLOR_WHITE
        at Button.pressed,      db 0
        at Button.enabled,      db 1
    iend

; String data
window_title    db 'GUI OS Window', 0
alt_title       db 'Modified!', 0
button1_text    db 'Color', 0
button2_text      db 'Title', 0
button3_text    db 'X', 0
clock_text      db '12:34', 0
