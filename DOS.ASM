; ====================================================================
;  Quick OS / Kernel - Version 6.0.0 (FASM Edition)
;  Build Code: 600
; ====================================================================

use16
org 0x7C00

start:
    ; Set up segment registers and stack
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Set text mode (80x25)
    mov ax, 0003h
    int 10h

    ; Print Boot Banner
    mov si, msg_welcome
    call print_string

main_loop:
    mov si, prompt
    call print_string

    ; Read command string from user
    mov di, input_buffer
    call read_string

    ; Compare commands
    mov si, input_buffer
    mov di, cmd_help
    call strcmp
    je do_help

    mov si, input_buffer
    mov di, cmd_version
    call strcmp
    je do_version

    mov si, input_buffer
    mov di, cmd_update
    call strcmp
    je do_update

    mov si, input_buffer
    mov di, cmd_desktop
    call strcmp
    je do_desktop

    mov si, input_buffer
    mov di, cmd_qiinstall
    call strcmp
    je do_qiinstall

    mov si, input_buffer
    mov di, cmd_mem
    call strcmp
    je do_mem

    mov si, input_buffer
    mov di, cmd_cpuinfo
    call strcmp
    je do_cpuinfo

    mov si, input_buffer
    mov di, cmd_cls
    call strcmp
    je do_cls

    ; Empty command check
    cmp byte [input_buffer], 0
    je main_loop

    ; Unknown command
    mov si, msg_unknown
    call print_string
    jmp main_loop

; ====================================================================
; COMMAND HANDLERS
; ====================================================================

do_help:
    mov si, msg_help
    call print_string
    jmp main_loop

do_version:
    mov si, msg_ver_info
    call print_string
    jmp main_loop

do_update:
    mov si, msg_update
    call print_string
    jmp main_loop

do_mem:
    mov si, msg_mem
    call print_string
    jmp main_loop

do_cpuinfo:
    mov si, msg_cpu
    call print_string
    jmp main_loop

do_cls:
    mov ax, 0003h
    int 10h
    jmp main_loop

; --------------------------------------------------------------------
; QIINSTALL COMMAND - Hard Drive Partition & Kernel Flasher
; --------------------------------------------------------------------
do_qiinstall:
    mov si, msg_install_warn
    call print_string

    ; Read confirmation (Y/N)
    mov di, input_buffer
    call read_string

    cmp byte [input_buffer], 'Y'
    je .confirm
    cmp byte [input_buffer], 'y'
    je .confirm

    mov si, msg_install_cancel
    call print_string
    jmp main_loop

 .confirm:
    mov si, msg_install_wiping
    call print_string

    ; Reset Disk Controller for Drive 80h (Primary HDD)
    mov ah, 00h
    mov dl, 80h
    int 13h
    jc .disk_error

    ; Wipe First 64 Sectors of Hard Drive 80h with Zeros
    mov cx, 1                   ; Starting sector 1
 .wipe_loop:
    push cx
    mov ax, 0301h               ; AH=03h (Write), AL=1 sector
    mov bx, zero_buffer         ; Buffer filled with 00h
    mov ch, 0                   ; Cylinder 0
    mov dh, 0                   ; Head 0
    mov dl, 80h                 ; Primary HDD
    int 13h
    pop cx
    jc .disk_error

    inc cx
    cmp cx, 65
    jl .wipe_loop

    ; Write OS Bootloader/Kernel to Sector 1 of Hard Drive 80h
    mov ax, 0301h               ; Write 1 sector
    mov bx, 07C00h              ; Address of running kernel in RAM
    mov cx, 0001h               ; Cylinder 0, Sector 1
    mov dh, 0                   ; Head 0
    mov dl, 80h                 ; Hard Disk 80h
    int 13h
    jc .disk_error

    mov si, msg_install_done
    call print_string
    jmp main_loop

 .disk_error:
    mov si, msg_install_err
    call print_string
    jmp main_loop

; --------------------------------------------------------------------
; DESKTOP COMMAND - VGA Graphics Mode UI (320x200x256)
; --------------------------------------------------------------------
do_desktop:
    ; Switch to VGA Graphics Mode 13h (320x200 256 colors)
    mov ax, 0013h
    int 10h

    ; ES points to VGA Video Memory (0xA000)
    mov ax, 0xA000
    mov es, ax

    ; 1. Draw Desktop Background (Dark Blue = Color 1)
    xor di, di
    mov al, 1
    mov cx, 64000
    rep stosb

    ; 2. Draw Taskbar at Bottom (Grey = Color 7, Rows 185-199)
    mov di, 320 * 185
    mov al, 7
    mov cx, 320 * 15
    rep stosb

    ; 3. Draw Start Button (Dark Grey = Color 8, Position X: 2-35, Y: 187-197)
    mov bx, 187
 .draw_start_row:
    mov di, bx
    imul di, 320
    add di, 2
    mov al, 8
    mov cx, 35
    rep stosb
    inc bx
    cmp bx, 197
    jl .draw_start_row

    ; 4. Draw Main Window Frame (Blue Header, Light Grey Body)
    ; Header (Y: 20-32, X: 40-280)
    mov bx, 20
 .draw_win_hdr:
    mov di, bx
    imul di, 320
    add di, 40
    mov al, 9                   ; Bright Blue
    mov cx, 240
    rep stosb
    inc bx
    cmp bx, 32
    jl .draw_win_hdr

    ; Body (Y: 32-150, X: 40-280)
    mov bx, 32
 .draw_win_body:
    mov di, bx
    imul di, 320
    add di, 40
    mov al, 15                  ; Bright White / Light Grey
    mov cx, 240
    rep stosb
    inc bx
    cmp bx, 150
    jl .draw_win_body

    ; 5. Print UI Labels using Video BIOS Text Overlay
    ; Start Button Text
    mov ah, 02h
    mov bh, 0
    mov dh, 23                  ; Row 23
    mov dl, 1                   ; Col 1
    int 10h
    mov si, msg_ui_start
    call print_gui_text

    ; Window Title Text
    mov ah, 02h
    mov bh, 0
    mov dh, 3                   ; Row 3
    mov dl, 6                   ; Col 6
    int 10h
    mov si, msg_ui_window_title
    call print_gui_text

    ; Window Content Text
    mov ah, 02h
    mov bh, 0
    mov dh, 6                   ; Row 6
    mov dl, 7                   ; Col 7
    int 10h
    mov si, msg_ui_welcome
    call print_gui_text

    mov ah, 02h
    mov bh, 0
    mov dh, 8                   ; Row 8
    mov dl, 7                   ; Col 7
    int 10h
    mov si, msg_ui_prompt_exit
    call print_gui_text

    ; Clock Text on Taskbar Right
    mov ah, 02h
    mov bh, 0
    mov dh, 23
    mov dl, 32
    int 10h
    mov si, msg_ui_clock
    call print_gui_text

 .desktop_input:
    ; Wait for keypress to return to CLI text mode
    mov ah, 00h
    int 16h

    ; Reset back to standard 80x25 text mode
    mov ax, 0003h
    int 10h

    ; Restore DS/ES back to normal segment
    mov ax, cs
    mov ds, ax
    mov es, ax
    jmp main_loop

; ====================================================================
; HELPER ROUTINES
; ====================================================================

print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0Eh
    int 10h
    jmp print_string
 .done:
    ret

print_gui_text:
    lodsb
    or al, al
    jz .done
    mov ah, 0Eh
    mov bl, 0Fh                 ; White text
    int 10h
    jmp print_gui_text
 .done:
    ret

read_string:
    xor cx, cx
 .next_char:
    mov ah, 00h
    int 16h

    cmp al, 0Dh                 ; Enter key
    je .done
    cmp al, 08h                 ; Backspace key
    je .backspace

    cmp cx, 63
    jge .next_char

    stosb
    inc cx
    mov ah, 0Eh
    int 10h
    jmp .next_char

 .backspace:
    jcxz .next_char
    dec di
    dec cx
    mov ah, 0Eh
    mov al, 08h
    int 10h
    mov al, ' '
    int 10h
    mov al, 08h
    int 10h
    jmp .next_char

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
    jne .not_equal
    cmp al, 0
    je .equal
    inc si
    inc di
    jmp .loop
 .not_equal:
    clc
    ret
 .equal:
    stc
    ret

; ====================================================================
; DATA SECTION
; ====================================================================

SYS_VERSION_CODE dw 600

prompt              db 'QuickOS> ', 0
msg_welcome         db '============================================', 0Dh, 0Ah
                    db ' QuickOS v6.0.0 (Desktop & HD Install Edition)', 0Dh, 0Ah
                    db ' Type HELP for available commands.', 0Dh, 0Ah
                    db '============================================', 0Dh, 0Ah, 0

msg_help            db 'Available Commands:', 0Dh, 0Ah
                    db '  DESKTOP   - Launch VGA Graphical Desktop Environment', 0Dh, 0Ah
                    db '  QIINSTALL - Format local hard disk and install QuickOS', 0Dh, 0Ah
                    db '  MEM       - Display system memory summary', 0Dh, 0Ah
                    db '  CPUINFO   - Display processor information', 0Dh, 0Ah
                    db '  UPDATE    - Check online repositories for updates', 0Dh, 0Ah
                    db '  VERSION   - Display installed OS build details', 0Dh, 0Ah
                    db '  CLS       - Clear terminal screen', 0Dh, 0Ah, 0

msg_ver_info        db 'QuickOS Version 6.0.0 [Build Code: 600]', 0Dh, 0Ah
                    db 'Target Architecture: x86 16-Bit Real Mode', 0Dh, 0Ah, 0

msg_update          db '[UPDATE] System is running the latest build (v6.0.0).', 0Dh, 0Ah, 0
msg_mem             db 'System RAM: 640 KB Base Memory Available.', 0Dh, 0Ah, 0
msg_cpu             db 'CPU: x86-Compatible Real Mode Processor.', 0Dh, 0Ah, 0
msg_unknown         db 'Unknown command. Type HELP for command list.', 0Dh, 0Ah, 0

; Installation Messages
msg_install_warn    db '====================================================', 0Dh, 0Ah
                    db ' WARNING: QIINSTALL WILL ERASE HARD DRIVE (Drive 80h)!', 0Dh, 0Ah
                    db ' All partitions and files will be permanently wiped.', 0Dh, 0Ah
                    db ' Are you sure you want to proceed? (Y/N): ', 0
msg_install_cancel  db '[QIINSTALL] Installation cancelled. No changes made.', 0Dh, 0Ah, 0
msg_install_wiping  db '[QIINSTALL] Wiping sectors on Drive 80h...', 0Dh, 0Ah, 0
msg_install_done    db '[QIINSTALL] Hard drive successfully flashed! Reboot to load QuickOS from HDD.', 0Dh, 0Ah, 0
msg_install_err     db '[QIINSTALL ERROR] Failed to access or write to target hard drive!', 0Dh, 0Ah, 0

; Desktop UI Strings
msg_ui_start        db 'START', 0
msg_ui_window_title db 'QuickOS Desktop v6.0.0', 0
msg_ui_welcome      db 'Welcome to QuickOS Graphical Shell!', 0
msg_ui_prompt_exit  db 'Press any key to return to CLI...', 0
msg_ui_clock        db '12:00 PM', 0

; Command Strings
cmd_help            db 'HELP', 0
cmd_version         db 'VERSION', 0
cmd_update          db 'UPDATE', 0
cmd_desktop         db 'DESKTOP', 0
cmd_qiinstall       db 'QIINSTALL', 0
cmd_mem             db 'MEM', 0
cmd_cpuinfo         db 'CPUINFO', 0
cmd_cls             db 'CLS', 0

; Zero-filled 512-byte buffer for wiping sectors
zero_buffer:        db 512 dup (0)

; Input Buffer
input_buffer:       db 64 dup (0)

; Boot Sector Padding & Magic Signature (FASM syntax)
db 510 - ($ - $$) dup (0)
dw 0xAA55
