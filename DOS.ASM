; ====================================================================
;  QuickOS v6.0.0 - FASM 512-Byte Boot Sector Edition
; ====================================================================

use16
org 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov ax, 0003h
    int 10h

    mov si, msg_welcome
    call print_string

main_loop:
    mov si, prompt
    call print_string

    mov di, input_buffer
    call read_string

    cmp byte [input_buffer], 0
    je main_loop

    ; Command checks
    mov si, input_buffer
    mov di, cmd_desktop
    call strcmp
    je do_desktop

    mov si, input_buffer
    mov di, cmd_qiinstall
    call strcmp
    je do_qiinstall

    mov si, input_buffer
    mov di, cmd_help
    call strcmp
    je do_help

    mov si, input_buffer
    mov di, cmd_cls
    call strcmp
    je do_cls

    mov si, msg_unknown
    call print_string
    jmp main_loop

; --- COMMAND HANDLERS ---

do_help:
    mov si, msg_help
    call print_string
    jmp main_loop

do_cls:
    mov ax, 0003h
    int 10h
    jmp main_loop

do_qiinstall:
    mov si, msg_install_warn
    call print_string

    mov di, input_buffer
    call read_string

    cmp byte [input_buffer], 'Y'
    je .confirm
    cmp byte [input_buffer], 'y'
    je .confirm
    jmp main_loop

 .confirm:
    mov ah, 00h
    mov dl, 80h
    int 13h

    ; Wipe first 16 sectors of Drive 80h
    mov cx, 1
 .wipe:
    push cx
    mov ax, 0301h
    mov bx, zero_buf
    mov ch, 0
    mov dh, 0
    mov dl, 80h
    int 13h
    pop cx
    inc cx
    cmp cx, 17
    jl .wipe

    ; Write bootloader to HDD sector 1
    mov ax, 0301h
    mov bx, 07C00h
    mov cx, 0001h
    mov dh, 0
    mov dl, 80h
    int 13h

    mov si, msg_installed
    call print_string
    jmp main_loop

do_desktop:
    mov ax, 0013h               ; 320x200 256-color VGA
    int 10h

    mov ax, 0xA000
    mov es, ax

    ; Blue Background
    xor di, di
    mov al, 1
    mov cx, 64000
    rep stosb

    ; Taskbar
    mov di, 320 * 185
    mov al, 7
    mov cx, 320 * 15
    rep stosb

    ; Window Box
    mov bx, 30
 .win_row:
    mov di, bx
    imul di, 320
    add di, 40
    mov al, 15
    mov cx, 240
    rep stosb
    inc bx
    cmp bx, 140
    jl .win_row

    ; UI Text
    mov ah, 02h
    mov bh, 0
    mov dh, 6
    mov dl, 7
    int 10h
    mov si, msg_ui_text
    call print_string

    ; Wait Key
    mov ah, 00h
    int 16h

    ; Reset Text Mode
    mov ax, 0003h
    int 10h
    mov ax, cs
    mov ds, ax
    mov es, ax
    jmp main_loop

; --- ROUTINES ---

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0Eh
    int 10h
    jmp print_string
 .done:
    ret

read_string:
    xor cx, cx
 .next:
    mov ah, 00h
    int 16h
    cmp al, 0Dh
    je .done
    cmp cx, 31
    jge .next
    stosb
    inc cx
    mov ah, 0Eh
    int 10h
    jmp .next
 .done:
    mov byte [di], 0
    mov ah, 0Eh
    mov al, 0Dh
    int 10h
    mov al, 0Ah
    int 10h
    ret

strcmp:
 .loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .diff
    cmp al, 0
    je .same
    inc si
    inc di
    jmp .loop
 .diff:
    clc
    ret
 .same:
    stc
    ret

; --- DATA SECTION ---

prompt          db 'QuickOS> ', 0
msg_welcome     db 'QuickOS v6.0 (Type HELP)', 0Dh, 0Ah, 0
msg_help        db 'Cmds: DESKTOP, QIINSTALL, CLS', 0Dh, 0Ah, 0
msg_unknown     db 'Unknown cmd.', 0Dh, 0Ah, 0
msg_install_warn db 'Wipe Drive 80h? (Y/N): ', 0
msg_installed   db 'Installed to HDD!', 0Dh, 0Ah, 0
msg_ui_text     db 'QuickOS GUI - Press key to exit', 0

cmd_desktop     db 'DESKTOP', 0
cmd_qiinstall   db 'QIINSTALL', 0
cmd_help        db 'HELP', 0
cmd_cls         db 'CLS', 0

zero_buf:       db 0
input_buffer:   db 32 dup (0)

; Pad exactly to 510 bytes, then add boot signature
rb 510 - ($ - $$)
dw 0xAA55
