; mouse.asm - Advanced PS/2 Mouse Driver
[BITS 32]

; PS/2 Mouse Driver for GUI OS
; Provides comprehensive mouse support with proper packet handling

; Mouse data structure
struc MouseData
    .buttons    resb 1      ; Button states
    .x_movement resb 1      ; X movement delta
    .y_movement resb 1      ; Y movement delta
    .x_position resd 1      ; Absolute X position
    .y_position resd 1      ; Absolute Y position
endstruc

; Mouse constants
MOUSE_IRQ           equ 12
MOUSE_CMD_PORT      equ 0x64
MOUSE_DATA_PORT     equ 0x60
MOUSE_ENABLE        equ 0xA8
MOUSE_DISABLE       equ 0xA7
MOUSE_WRITE         equ 0xD4
MOUSE_SET_DEFAULTS  equ 0xF6
MOUSE_ENABLE_DATA   equ 0xF4
MOUSE_DISABLE_DATA  equ 0xF5
MOUSE_RESET         equ 0xFF

; Initialize PS/2 mouse
init_ps2_mouse:
    pusha
    
    ; Disable mouse
    call mouse_wait_cmd
    mov al, MOUSE_DISABLE
    out MOUSE_CMD_PORT, al
    
    ; Enable mouse interface
    call mouse_wait_cmd
    mov al, MOUSE_ENABLE
    out MOUSE_CMD_PORT, al
    
    ; Send mouse reset command
    call mouse_send_command
    db MOUSE_RESET
    
    ; Wait for acknowledgment
    call mouse_read_data
    cmp al, 0xFA        ; ACK
    jne .init_failed
    
    ; Wait for self-test result
    call mouse_read_data
    cmp al, 0xAA        ; Self-test passed
    jne .init_failed
    
    ; Wait for mouse ID
    call mouse_read_data
    
    ; Set mouse defaults
    mov al, MOUSE_SET_DEFAULTS
    call mouse_send_command_byte
    
    ; Enable data reporting
    mov al, MOUSE_ENABLE_DATA
    call mouse_send_command_byte
    
    ; Initialize mouse position
    mov dword [mouse_data + MouseData.x_position], 160
    mov dword [mouse_data + MouseData.y_position], 100
    mov byte [mouse_data + MouseData.buttons], 0
    
    ; Set packet state
    mov byte [mouse_packet_state], 0
    
    popa
    ret
    
.init_failed:
    ; Mouse initialization failed
    popa
    ret

; Send command byte to mouse
mouse_send_command_byte:
    push eax
    call mouse_send_command
    pop eax
    ret

; Send command to mouse
mouse_send_command:
    push eax
    
    ; Tell controller we want to write to mouse
    call mouse_wait_cmd
    mov al, MOUSE_WRITE
    out MOUSE_CMD_PORT, al
    
    ; Send the actual command
    call mouse_wait_data
    pop eax
    out MOUSE_DATA_PORT, al
    
    ; Wait for acknowledgment
    call mouse_read_data
    cmp al, 0xFA        ; Check for ACK
    
    ret

; Wait for mouse controller command ready
mouse_wait_cmd:
    push eax
.wait:
    in al, MOUSE_CMD_PORT
    test al, 2          ; Test input buffer
    jnz .wait
    pop eax
    ret

; Wait for mouse data ready
mouse_wait_data:
    push eax
.wait:
    in al, MOUSE_CMD_PORT
    test al, 1          ; Test output buffer
    jz .wait
    pop eax
    ret

; Read data from mouse
mouse_read_data:
    call mouse_wait_data
    in al, MOUSE_DATA_PORT
    ret

; Handle mouse interrupt/input
handle_mouse_interrupt:
    pusha
    
    ; Read mouse data
    in al, MOUSE_DATA_PORT
    
    ; Process based on packet state
    mov bl, [mouse_packet_state]
    cmp bl, 0
    je .first_byte
    cmp bl, 1
    je .second_byte
    cmp bl, 2
    je .third_byte
    jmp .done

.first_byte:
    ; First byte contains button states and flags
    mov [mouse_packet + 0], al
    mov byte [mouse_packet_state], 1
    jmp .done

.second_byte:
    ; Second byte contains X movement
    mov [mouse_packet + 1], al
    mov byte [mouse_packet_state], 2
    jmp .done

.third_byte:
    ; Third byte contains Y movement
    mov [mouse_packet + 2], al
    mov byte [mouse_packet_state], 0  ; Reset for next packet
    
    ; Process complete packet
    call process_mouse_packet
    jmp .done

.done:
    popa
    ret

; Process complete mouse packet
process_mouse_packet:
    pusha
    
    ; Extract button states
    mov al, [mouse_packet + 0]
    mov [mouse_data + MouseData.buttons], al
    
    ; Extract X movement
    mov al, [mouse_packet + 1]
    mov [mouse_data + MouseData.x_movement], al
    
    ; Check if X movement is negative (bit 4 of first byte)
    mov bl, [mouse_packet + 0]
    test bl, 0x10
    jz .positive_x
    
    ; Negative X movement - sign extend
    or al, 0x80
    
.positive_x:
    ; Update X position
    movsx eax, al       ; Sign extend to 32-bit
    add eax, [mouse_data + MouseData.x_position]
    
    ; Clamp to screen bounds
    cmp eax, 0
    jge .x_not_negative
    mov eax, 0
.x_not_negative:
    cmp eax, 319        ; Screen width - 1
    jle .x_not_too_big
    mov eax, 319
.x_not_too_big:
    mov [mouse_data + MouseData.x_position], eax
    
    ; Extract Y movement
    mov al, [mouse_packet + 2]
    mov [mouse_data + MouseData.y_movement], al
    
    ; Check if Y movement is negative (bit 5 of first byte)
    mov bl, [mouse_packet + 0]
    test bl, 0x20
    jz .positive_y
    
    ; Negative Y movement - sign extend
    or al, 0x80
    
.positive_y:
    ; Update Y position (Y is inverted for mouse)
    movsx eax, al       ; Sign extend to 32-bit
    neg eax             ; Invert Y movement
    add eax, [mouse_data + MouseData.y_position]
    
    ; Clamp to screen bounds
    cmp eax, 0
    jge .y_not_negative
    mov eax, 0
.y_not_negative:
    cmp eax, 199        ; Screen height - 1
    jle .y_not_too_big
    mov eax, 199
.y_not_too_big:
    mov [mouse_data + MouseData.y_position], eax
    
    ; Signal that mouse data has been updated
    mov byte [mouse_updated], 1
    
    popa
    ret

; Get mouse position
; Returns: EAX = X position, EBX = Y position
get_mouse_position:
    mov eax, [mouse_data + MouseData.x_position]
    mov ebx, [mouse_data + MouseData.y_position]
    ret

; Get mouse buttons
; Returns: AL = button states (bit 0 = left, bit 1 = right, bit 2 = middle)
get_mouse_buttons:
    mov al, [mouse_data + MouseData.buttons]
    and al, 0x07        ; Mask to only button bits
    ret

; Check if mouse has been updated since last check
; Returns: AL = 1 if updated, 0 if not
mouse_has_updated:
    mov al, [mouse_updated]
    mov byte [mouse_updated], 0  ; Clear flag
    ret

; Advanced mouse functionality
; Check if left button is pressed
is_left_button_pressed:
    call get_mouse_buttons
    and al, 0x01
    ret

; Check if right button is pressed
is_right_button_pressed:
    call get_mouse_buttons
    and al, 0x02
    shr al, 1
    ret

; Check if middle button is pressed
is_middle_button_pressed:
    call get_mouse_buttons
    and al, 0x04
    shr al, 2
    ret

; Check if mouse is over rectangular area
; Input: EAX = rect_x, EBX = rect_y, ECX = rect_width, EDX = rect_height
; Returns: AL = 1 if mouse is over area, 0 if not
is_mouse_over_rect:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    ; Get mouse position
    mov esi, [mouse_data + MouseData.x_position]
    mov edi, [mouse_data + MouseData.y_position]
    
    ; Check X bounds
    cmp esi, eax        ; mouse_x >= rect_x
    jl .not_over
    add eax, ecx        ; rect_x + rect_width
    cmp esi, eax        ; mouse_x < rect_x + rect_width
    jge .not_over
    
    ; Check Y bounds
    cmp edi, ebx        ; mouse_y >= rect_y
    jl .not_over
    add ebx, edx        ; rect_y + rect_height
    cmp edi, ebx        ; mouse_y < rect_y + rect_height
    jge .not_over
    
    ; Mouse is over rectangle
    mov al, 1
    jmp .done
    
.not_over:
    mov al, 0
    
.done:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

; Data section
mouse_data:
    istruc MouseData
        at MouseData.buttons,    db 0
        at MouseData.x_movement, db 0
        at MouseData.y_movement, db 0
        at MouseData.x_position, dd 160
        at MouseData.y_position, dd 100
    iend

mouse_packet db 0, 0, 0        ; 3-byte mouse packet buffer
mouse_packet_state db 0        ; Current packet byte being received
mouse_updated db 0             ; Flag indicating mouse data updated
