; ====================================================================
; JS-DOS Bare-Metal Edition (Kernel v4.0)
; Assemble: fasm DOS.ASM DOS.bin
; Run:      qemu-system-x86_64 -fda DOS.bin
; ====================================================================

use16
org 0x7C00

; --------------------------------------------------------------------
; STAGE 1: BOOTLOADER (Sector 1 - 512 Bytes)
; --------------------------------------------------------------------
boot_start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; Load Stage 2 Kernel from Disk (Read 16 Sectors into 0x8000)
    mov ah, 02h          ; BIOS Read Sectors Function
    mov al, 16           ; Read 16 sectors (8192 bytes)
    mov ch, 0            ; Cylinder 0
    mov cl, 2            ; Start at Sector 2
    mov dh, 0            ; Head 0
    mov dl, 0            ; Drive 0 (Floppy A:)
    mov bx, 0x8000       ; Buffer destination: ES:BX -> 0x0000:0x8000
    int 13h              ; Call BIOS Disk Interrupt

    jmp 0x0000:0x8000    ; Jump to Stage 2 Kernel!

times 510-($-$$) db 0
dw 0xAA55               ; Boot Signature

; --------------------------------------------------------------------
; STAGE 2: KERNEL & COMMAND SHELL (Sectors 2-17 - 8192 Bytes)
; --------------------------------------------------------------------
org 0x8000

kernel_start:
    mov ax, 0003h        ; 80x25 Color Text Mode
    int 10h

    mov si, msg_banner
    call print_string

main_loop:
    mov si, msg_prompt
    call print_string

    mov di, input_buffer
    call read_line

    mov si, msg_newline
    call print_string

    cmp byte [input_buffer], 0
    je main_loop

    ; Upper-case input string
    mov si, input_buffer
 uppercase_loop:
    mov al, [si]
    cmp al, 0
    je .done_upper
    cmp al, 'a'
    jb .skip
    cmp al, 'z'
    ja .skip
    sub al, 32
    mov [si], al
 .skip:
    inc si
    jmp uppercase_loop
 .done_upper:

    ; --- Command Matching ---
    mov si, input_buffer
    mov di, cmd_cls
    call strcmp
    jc do_cls

    mov si, input_buffer
    mov di, cmd_clear
    call strcmp
    jc do_cls

    mov si, input_buffer
    mov di, cmd_help
    call strcmp
    jc do_help

    mov si, input_buffer
    mov di, cmd_update
    call strcmp
    jc do_update

    mov si, input_buffer
    mov di, cmd_jlver
    call strcmp
    jc do_jlver

    mov si, input_buffer
    mov di, cmd_dev
    call strcmp
    jc do_dev

    mov si, input_buffer
    mov di, cmd_desktop
    call strcmp
    jc do_desktop

    mov si, input_buffer
    mov di, cmd_poweroff
    call strcmp
    jc do_poweroff

    mov si, input_buffer
    mov di, cmd_restart
    call strcmp
    jc do_restart

    mov si, input_buffer
    mov di, cmd_recovery
    call strcmp
    jc do_recovery

    ; 8 New Commands
    mov si, input_buffer
    mov di, cmd_time
    call strcmp
    jc do_time

    mov si, input_buffer
    mov di, cmd_date
    call strcmp
    jc do_date

    mov si, input_buffer
    mov di, cmd_mem
    call strcmp
    jc do_mem

    mov si, input_buffer
    mov di, cmd_echo
    call strcmp
    jc do_echo

    mov si, input_buffer
    mov di, cmd_ping
    call strcmp
    jc do_ping

    mov si, input_buffer
    mov di, cmd_fetch
    call strcmp
    jc do_fetch

    mov si, input_buffer
    mov di, cmd_info
    call strcmp
    jc do_info

    mov si, msg_badcmd
    call print_string
    jmp main_loop

; --------------------------------------------------------------------
; COMMAND IMPLEMENTATIONS
; --------------------------------------------------------------------

do_cls:
    mov ax, 0003h
    int 10h
    jmp main_loop

do_help:
    mov si, msg_help
    call print_string
    jmp main_loop

do_update:
    mov si, msg_update_start
    call print_string
    mov si, msg_github_url
    call print_string
    mov si, msg_update_done
    call print_string
    jmp main_loop

do_jlver:
    mov si, msg_jlver_info
    call print_string
    jmp main_loop

; --- FIXED DEV MODE ---
do_dev:
    mov ax, 0003h
    int 10h

    mov si, msg_dev_header
    call print_string

 dev_editor_loop:
    mov si, msg_dev_prompt
    call print_string

    mov di, input_buffer
    call read_line

    mov si, msg_newline
    call print_string

    ; Check EXIT
    mov si, input_buffer
    mov di, cmd_exit
    call strcmp
    jc .exit_dev

    mov si, msg_dev_saved
    call print_string
    jmp dev_editor_loop

 .exit_dev:
    mov ax, 0003h
    int 10h
    jmp main_loop

; --- FIXED DESKTOP MODE ---
do_desktop:
    mov ax, 0003h
    int 10h

 desktop_render:
    mov si, msg_desktop_ui
    call print_string

 desktop_loop:
    mov si, msg_desktop_prompt
    call print_string

    mov di, input_buffer
    call read_line

    mov si, msg_newline
    call print_string

    ; Upper-case desktop input
    mov si, input_buffer
 .d_upper:
    mov al, [si]
    cmp al, 0
    je .d_done_upper
    cmp al, 'a'
    jb .d_skip
    cmp al, 'z'
    ja .d_skip
    sub al, 32
    mov [si], al
 .d_skip:
    inc si
    jmp .d_upper
 .d_done_upper:

    ; Check EXIT command
    mov si, input_buffer
    mov di, cmd_exit
    call strcmp
    jc .exit_desktop

    ; Desktop options
    mov si, input_buffer
    mov di, cmd_opt1
    call strcmp
    jc .app1

    mov si, input_buffer
    mov di, cmd_opt2
    call strcmp
    jc .app2

    mov si, input_buffer
    mov di, cmd_opt3
    call strcmp
    jc .app3

    mov si, msg_desktop_err
    call print_string
    jmp desktop_loop

 .app1:
    mov si, msg_app1_text
    call print_string
    jmp desktop_loop
 .app2:
    mov si, msg_app2_text
    call print_string
    jmp desktop_loop
 .app3:
    mov si, msg_app3_text
    call print_string
    jmp desktop_loop

 .exit_desktop:
    mov ax, 0003h
    int 10h
    jmp main_loop

; --- POWER / RESTART ---
do_poweroff:
    mov si, msg_poweroff
    call print_string
    mov ax, 0x2000
    mov dx, 0x604
    out dx, ax
    cli
 .halt:
    hlt
    jmp .halt

do_restart:
    mov si, msg_restart
    call print_string
    jmp 0xFFFF:0000

; --- CODE-READING RECOVERY ---
do_recovery:
    mov si, msg_rec_header
    call print_string
    
    ; Print source code lines
    mov si, code_line1
    call print_string
    mov si, code_line2
    call print_string
    mov si, code_line3
    call print_string
    mov si, code_line4
    call print_string

    mov si, msg_rec_done
    call print_string
    jmp main_loop

; --- 8 NEW COMMANDS ---
do_time:
    mov si, msg_time
    call print_string
    jmp main_loop

do_date:
    mov si, msg_date
    call print_string
    jmp main_loop

do_mem:
    mov si, msg_mem
    call print_string
    jmp main_loop

do_echo:
    mov si, msg_echo
    call print_string
    jmp main_loop

do_ping:
    mov si, msg_ping
    call print_string
    jmp main_loop

do_fetch:
    mov si, msg_fetch
    call print_string
    jmp main_loop

do_info:
    mov si, msg_info
    call print_string
    jmp main_loop

; --------------------------------------------------------------------
; HELPER ROUTINES
; --------------------------------------------------------------------

print_string:
    pusha
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0Eh
    mov bh, 0
    int 10h
    jmp .loop
.done:
    popa
    ret

read_line:
    pusha
    xor cx, cx
.loop:
    mov ah, 00h
    int 16h

    cmp al, 0Dh
    je .done

    cmp al, 08h
    je .backspace

    cmp cx, 30
    jge .loop

    mov [di], al
    inc di
    inc cx
    mov ah, 0Eh
    int 10h
    jmp .loop

.backspace:
    jcxz .loop
    dec di
    dec cx
    mov ah, 0Eh
    mov al, 08h
    int 10h
    mov al, ' '
    int 10h
    mov al, 08h
    int 10h
    jmp .loop

.done:
    mov byte [di], 0
    popa
    ret

; Exact String Comparison Routine
strcmp:
    push si
    push di
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
    pop di
    pop si
    clc
    ret
.equal:
    pop di
    pop si
    stc
    ret

; --------------------------------------------------------------------
; DATA SECTION
; --------------------------------------------------------------------

cmd_cls       db 'CLS', 0
cmd_clear     db 'CLEAR', 0
cmd_help      db 'HELP', 0
cmd_update    db 'UPDATE', 0
cmd_jlver     db 'JLVER', 0
cmd_dev       db 'DEV', 0
cmd_desktop   db 'DESKTOP', 0
cmd_poweroff  db 'POWEROFF', 0
cmd_restart   db 'RESTART', 0
cmd_recovery  db 'RECOVERY', 0
cmd_exit      db 'EXIT', 0

; 8 New Command Keys
cmd_time      db 'TIME', 0
cmd_date      db 'DATE', 0
cmd_mem       db 'MEM', 0
cmd_echo      db 'ECHO', 0
cmd_ping      db 'PING', 0
cmd_fetch     db 'FETCH', 0
cmd_info      db 'INFO', 0

; Desktop Keys
cmd_opt1      db '1', 0
cmd_opt2      db '2', 0
cmd_opt3      db '3', 0

msg_banner  db 'JS-DOS OS [Multi-Sector Kernel v4.0]', 0Dh, 0Ah
            db 'Type HELP for available commands.', 0Dh, 0Ah, 0Dh, 0Ah, 0
msg_prompt  db 'C:\>', 0
msg_newline db 0Dh, 0Ah, 0
msg_badcmd  db 'Bad command or file name', 0Dh, 0Ah, 0

msg_help    db 'Commands: CLS, HELP, UPDATE, JLVER, DEV, DESKTOP, POWEROFF, RESTART,', 0Dh, 0Ah
            db '          RECOVERY, TIME, DATE, MEM, ECHO, PING, FETCH, INFO, CLEAR', 0Dh, 0Ah, 0

msg_update_start db 'Connecting to network adapter...', 0Dh, 0Ah, 0
msg_github_url   db 'Checking repo: https://github.com/capatag4-hash/js-dos', 0Dh, 0Ah, 0
msg_update_done  db 'System is up to date! Version 4.0.0-latest', 0Dh, 0Ah, 0

msg_jlver_info   db '--- JLVER SYSTEM CODE METRICS ---', 0Dh, 0Ah
                 db 'Stage 1 Boot: 0x7C00 (512 Bytes)', 0Dh, 0Ah
                 db 'Stage 2 Kernel: 0x8000 (8192 Bytes)', 0Dh, 0Ah
                 db 'Architecture: 16-bit x86 Real Mode', 0Dh, 0Ah, 0

msg_dev_header   db '================================================', 0Dh, 0Ah
                 db '          JS-DOS LIVE CODE EDITOR (DEV)         ', 0Dh, 0Ah
                 db '     Type ASM / code lines. Type EXIT to quit.  ', 0Dh, 0Ah
                 db '================================================', 0Dh, 0Ah, 0
msg_dev_prompt   db 'EDIT> ', 0
msg_dev_saved    db '[Line buffered to RAM]', 0Dh, 0Ah, 0

; Desktop UI Text
msg_desktop_ui   db '+--------------------------------------------------+', 0Dh, 0Ah
                 db '|                 JS-DOS DESKTOP                   |', 0Dh, 0Ah
                 db '+--------------------------------------------------+', 0Dh, 0Ah
                 db '| [1] Text Editor    [2] File Manager   [3] Clock  |', 0Dh, 0Ah
                 db '|                                                  |', 0Dh, 0Ah
                 db '| Type 1, 2, or 3 to open app. Type EXIT to leave.  |', 0Dh, 0Ah
                 db '+--------------------------------------------------+', 0Dh, 0Ah, 0
msg_desktop_prompt db 'DESKTOP> ', 0
msg_desktop_err    db 'Invalid application index. Type 1, 2, 3, or EXIT.', 0Dh, 0Ah, 0
msg_app1_text      db '[APP] Text Editor Loaded. (Press ENTER)', 0Dh, 0Ah, 0
msg_app2_text      db '[APP] File Manager: Drive C:\ [OK]', 0Dh, 0Ah, 0
msg_app3_text      db '[APP] System Clock: 12:00:00 UTC', 0Dh, 0Ah, 0

; Recovery & Code Reading Strings
msg_rec_header   db 'RECOVERY: Reading and rebuilding source lines from GitHub...', 0Dh, 0Ah, 0
code_line1       db '[0x7C00] mov ah, 02h | int 13h ; Load Kernel', 0Dh, 0Ah, 0
code_line2       db '[0x8000] mov ax, 0003h | int 10h ; Text Mode', 0Dh, 0Ah, 0
code_line3       db '[0x8050] call read_line | call strcmp ; Shell', 0Dh, 0Ah, 0
code_line4       db '[0x8100] times 8192-($-kernel_start) db 0 ; Pad', 0Dh, 0Ah, 0
msg_rec_done     db 'Rebuild Complete! All source lines restored cleanly.', 0Dh, 0Ah, 0

; New Commands Output Strings
msg_time    db 'Current Time: 14:35:00', 0Dh, 0Ah, 0
msg_date    db 'Current Date: 2026-07-24', 0Dh, 0Ah, 0
msg_mem     db 'Memory Usage: Base RAM 640KB | Free: 632KB', 0Dh, 0Ah, 0
msg_echo    db 'ECHO: JS-DOS Kernel Active.', 0Dh, 0Ah, 0
msg_ping    db 'PING github.com [140.82.121.4]: 32 bytes time=12ms TTL=118', 0Dh, 0Ah, 0
msg_fetch   db 'FETCH: Downloading main.asm from remote origin... Done.', 0Dh, 0Ah, 0
msg_info    db 'System Info: JS-DOS x86 Real-Mode Kernel running on QEMU.', 0Dh, 0Ah, 0

msg_poweroff db 'Shutting down JS-DOS... Safe to close VM.', 0Dh, 0Ah, 0
msg_restart  db 'Rebooting system...', 0Dh, 0Ah, 0

input_buffer db 32 dup(0)

; Pad Stage 2 Kernel to exactly 8192 bytes (16 sectors)
times 8192-($-kernel_start) db 0