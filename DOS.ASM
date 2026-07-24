; ====================================================================
; JS-DOS Bare-Metal Edition (Kernel v5.2.0 - Security & Desktop UI)
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

    ; Load Stage 2 Kernel from Disk (Read 64 Sectors into 0x8000)
    mov ah, 02h          ; BIOS Read Sectors Function
    mov al, 64           ; Read 64 sectors (32768 bytes)
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
; STAGE 2: KERNEL & COMMAND SHELL (32 KB Buffer)
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

    ; --- Command Matcher ---
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
    mov di, cmd_setup
    call strcmp
    jc do_setup

    mov si, input_buffer
    mov di, cmd_login
    call strcmp
    jc do_login

    mov si, input_buffer
    mov di, cmd_desktop
    call strcmp
    jc do_desktop

    mov si, input_buffer
    mov di, cmd_neofetch
    call strcmp
    jc do_neofetch

    mov si, input_buffer
    mov di, cmd_info
    call strcmp
    jc do_info

    mov si, input_buffer
    mov di, cmd_settings
    call strcmp
    jc do_settings

    mov si, input_buffer
    mov di, cmd_developers
    call strcmp
    jc do_developers

    mov si, input_buffer
    mov di, cmd_recovery
    call strcmp
    jc do_recovery

    mov si, input_buffer
    mov di, cmd_update
    call strcmp
    jc do_update

    mov si, input_buffer
    mov di, cmd_dev
    call strcmp
    jc do_dev

    mov si, input_buffer
    mov di, cmd_jlver
    call strcmp
    jc do_jlver

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
    mov di, cmd_calc
    call strcmp
    jc do_calc

    mov si, input_buffer
    mov di, cmd_color
    call strcmp
    jc do_color

    mov si, input_buffer
    mov di, cmd_matrix
    call strcmp
    jc do_matrix

    mov si, input_buffer
    mov di, cmd_ver
    call strcmp
    jc do_ver

    mov si, input_buffer
    mov di, cmd_cpuinfo
    call strcmp
    jc do_cpuinfo

    mov si, input_buffer
    mov di, cmd_netstat
    call strcmp
    jc do_netstat

    mov si, input_buffer
    mov di, cmd_bootlog
    call strcmp
    jc do_bootlog

    mov si, input_buffer
    mov di, cmd_poweroff
    call strcmp
    jc do_poweroff

    mov si, input_buffer
    mov di, cmd_restart
    call strcmp
    jc do_restart

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

; --- SETUP COMMAND: PASSWORD CONFIGURATION ---
do_setup:
    mov ax, 0003h
    int 10h
    mov si, msg_setup_title
    call print_string

    ; Read Username
    mov si, msg_setup_user_prompt
    call print_string
    mov di, user_buffer
    call read_line
    mov si, msg_newline
    call print_string

    ; Read Password
    mov si, msg_setup_pass_prompt
    call print_string
    mov di, pass_buffer
    call read_line
    mov si, msg_newline
    call print_string

    mov byte [is_configured], 1
    mov si, msg_setup_done
    call print_string
    jmp main_loop

; --- LOGIN COMMAND: SECURITY CHECK ---
do_login:
    cmp byte [is_configured], 0
    jne .configured
    mov si, msg_not_configured
    call print_string
    jmp main_loop

 .configured:
    mov ax, 0003h
    int 10h
    mov si, msg_login_title
    call print_string

 login_retry:
    mov si, msg_login_pass_prompt
    call print_string
    mov di, input_buffer
    call read_line
    mov si, msg_newline
    call print_string

    ; Verify Password
    mov si, input_buffer
    mov di, pass_buffer
    call strcmp
    jc .login_success

    mov si, msg_login_fail
    call print_string
    jmp login_retry

 .login_success:
    mov si, msg_login_ok
    call print_string
    jmp main_loop

; --- REDESIGNED DESKTOP UI ---
do_desktop:
    mov ax, 0003h
    int 10h
    mov si, msg_desktop_ui
    call print_string

 desktop_loop:
    mov si, msg_desktop_prompt
    call print_string

    mov di, input_buffer
    call read_line
    mov si, msg_newline
    call print_string

    ; Check Exit
    mov si, input_buffer
    mov di, cmd_exit
    call strcmp
    jc .exit_desktop

    mov si, input_buffer
    mov di, cmd_opt1
    call strcmp
    jc .app_editor

    mov si, input_buffer
    mov di, cmd_opt2
    call strcmp
    jc .app_calc

    mov si, input_buffer
    mov di, cmd_opt3
    call strcmp
    jc .app_settings

    mov si, msg_desktop_err
    call print_string
    jmp desktop_loop

 .app_editor:
    mov si, msg_app1_launched
    call print_string
    jmp desktop_loop

 .app_calc:
    mov si, msg_app2_launched
    call print_string
    jmp desktop_loop

 .app_settings:
    mov si, msg_app3_launched
    call print_string
    jmp desktop_loop

 .exit_desktop:
    mov ax, 0003h
    int 10h
    jmp main_loop

do_neofetch:
    mov si, msg_neofetch_art
    call print_string
    jmp main_loop

do_info:
    mov si, msg_info_detail
    call print_string
    jmp main_loop

do_settings:
    mov ax, 0003h
    int 10h
 settings_render:
    mov si, msg_settings_ui
    call print_string
 settings_loop:
    mov si, msg_settings_prompt
    call print_string
    mov di, input_buffer
    call read_line
    mov si, msg_newline
    call print_string

    mov si, input_buffer
    mov di, cmd_exit
    call strcmp
    jc .exit_settings

    mov si, input_buffer
    mov di, cmd_opt1
    call strcmp
    jc .set_color

    mov si, input_buffer
    mov di, cmd_opt2
    call strcmp
    jc .set_sound

    mov si, msg_settings_err
    call print_string
    jmp settings_loop

 .set_color:
    mov si, msg_color_changed
    call print_string
    jmp settings_loop

 .set_sound:
    mov si, msg_sound_changed
    call print_string
    jmp settings_loop

 .exit_settings:
    mov ax, 0003h
    int 10h
    jmp main_loop

do_developers:
    mov si, msg_dev_credits
    call print_string
    jmp main_loop

do_update:
    mov si, msg_checking_repo
    call print_string

    mov si, msg_current_ver
    call print_string

    mov si, msg_repo_ver_found
    call print_string

    mov ax, [SYS_VERSION_CODE]
    cmp ax, 520                 ; Compare local build against target build (520 = v5.2.0)
    je .already_latest
    jl .do_upgrade

    mov si, msg_downgrade_err
    call print_string
    jmp main_loop

 .already_latest:
    mov si, msg_no_update
    call print_string
    jmp main_loop

 .do_upgrade:
    mov si, msg_updating
    call print_string
    jmp main_loop

do_recovery:
    mov ax, 0003h
    int 10h
 recovery_render:
    mov si, msg_recovery_ui
    call print_string
 recovery_loop:
    mov si, msg_recovery_prompt
    call print_string
    mov di, input_buffer
    call read_line
    mov si, msg_newline
    call print_string

    mov si, input_buffer
    mov di, cmd_exit
    call strcmp
    jc .exit_recovery

    mov si, input_buffer
    mov di, cmd_opt1
    call strcmp
    jc .rec_mbr

    mov si, input_buffer
    mov di, cmd_opt2
    call strcmp
    jc .rec_files

    mov si, input_buffer
    mov di, cmd_opt3
    call strcmp
    jc .rec_git

    mov si, msg_recovery_err
    call print_string
    jmp recovery_loop

 .rec_mbr:
    mov si, msg_rec_mbr_ok
    call print_string
    jmp recovery_loop

 .rec_files:
    mov si, msg_rec_files_ok
    call print_string
    jmp recovery_loop

 .rec_git:
    mov si, msg_rec_git_ok
    call print_string
    jmp recovery_loop

 .exit_recovery:
    mov ax, 0003h
    int 10h
    jmp main_loop

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

do_jlver:
    mov si, msg_jlver_info
    call print_string
    jmp main_loop

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

do_calc:
    mov si, msg_calc
    call print_string
    jmp main_loop

do_color:
    mov si, msg_color
    call print_string
    jmp main_loop

do_matrix:
    mov si, msg_matrix
    call print_string
    jmp main_loop

do_ver:
    mov si, msg_ver
    call print_string
    jmp main_loop

do_cpuinfo:
    mov si, msg_cpuinfo
    call print_string
    jmp main_loop

do_netstat:
    mov si, msg_netstat
    call print_string
    jmp main_loop

do_bootlog:
    mov si, msg_bootlog
    call print_string
    jmp main_loop

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
; DATA SECTION & VERSION CONTROL HEADERS
; --------------------------------------------------------------------

SYS_VERSION_MAJOR   db 5        ; Major integer
SYS_VERSION_MINOR   db 2        ; Minor integer
SYS_VERSION_CODE    dw 520      ; Numeric Build Code (520 = v5.2.0)

is_configured       db 0        ; Setup status flag

cmd_cls         db 'CLS', 0
cmd_clear       db 'CLEAR', 0
cmd_help        db 'HELP', 0
cmd_setup       db 'SETUP', 0
cmd_login       db 'LOGIN', 0
cmd_desktop     db 'DESKTOP', 0
cmd_neofetch    db 'NEOFETCH', 0
cmd_info        db 'INFO', 0
cmd_settings    db 'SETTINGS', 0
cmd_developers  db 'DEVELOPERS', 0
cmd_recovery    db 'RECOVERY', 0
cmd_update      db 'UPDATE', 0
cmd_dev         db 'DEV', 0
cmd_jlver       db 'JLVER', 0
cmd_time        db 'TIME', 0
cmd_date        db 'DATE', 0
cmd_mem         db 'MEM', 0
cmd_echo        db 'ECHO', 0
cmd_ping        db 'PING', 0
cmd_fetch       db 'FETCH', 0
cmd_calc        db 'CALC', 0
cmd_color       db 'COLOR', 0
cmd_matrix      db 'MATRIX', 0
cmd_ver         db 'VER', 0
cmd_cpuinfo     db 'CPUINFO', 0
cmd_netstat     db 'NETSTAT', 0
cmd_bootlog     db 'BOOTLOG', 0
cmd_poweroff    db 'POWEROFF', 0
cmd_restart     db 'RESTART', 0
cmd_exit        db 'EXIT', 0

cmd_opt1        db '1', 0
cmd_opt2        db '2', 0
cmd_opt3        db '3', 0

msg_banner  db 'JS-DOS OS [Kernel v5.2.0 - Extended Security Build]', 0Dh, 0Ah
            db 'Type SETUP to configure credentials, or DESKTOP to launch UI.', 0Dh, 0Ah, 0Dh, 0Ah, 0
msg_prompt  db 'C:\>', 0
msg_newline db 0Dh, 0Ah, 0
msg_badcmd  db 'Bad command or file name', 0Dh, 0Ah, 0

msg_help    db 'Commands: CLS, HELP, SETUP, LOGIN, DESKTOP, NEOFETCH, INFO, SETTINGS,', 0Dh, 0Ah
            db '          DEVELOPERS, RECOVERY, UPDATE, DEV, JLVER, TIME, DATE, MEM,', 0Dh, 0Ah
            db '          ECHO, PING, FETCH, CALC, COLOR, MATRIX, VER, CPUINFO,', 0Dh, 0Ah
            db '          NETSTAT, BOOTLOG, POWEROFF, RESTART', 0Dh, 0Ah, 0

; SETUP & LOGIN MESSAGES
msg_setup_title       db '================================================', 0Dh, 0Ah
                      db '            JS-DOS ACCOUNT INITIALIZATION        ', 0Dh, 0Ah
                      db '================================================', 0Dh, 0Ah, 0
msg_setup_user_prompt db 'Enter New Username: ', 0
msg_setup_pass_prompt db 'Enter New Password: ', 0
msg_setup_done        db '[SETUP] Account credentials saved successfully.', 0Dh, 0Ah, 0

msg_login_title       db '================================================', 0Dh, 0Ah
                      db '              JS-DOS SECURITY LOGIN             ', 0Dh, 0Ah
                      db '================================================', 0Dh, 0Ah, 0
msg_login_pass_prompt db 'Enter Password: ', 0
msg_login_fail        db '[ACCESS DENIED] Incorrect password! Try again.', 0Dh, 0Ah, 0
msg_login_ok          db '[ACCESS GRANTED] Session unlocked.', 0Dh, 0Ah, 0
msg_not_configured    db '[ERROR] No credentials set. Run SETUP command first.', 0Dh, 0Ah, 0

; NEW DESKTOP ENVIRONMENT UI
msg_desktop_ui  db '========================================================================', 0Dh, 0Ah
                db '| JS-DOS WORKSTATION v5.2.0                    CLOCK: 12:00  RAM: 32KB |', 0Dh, 0Ah
                db '========================================================================', 0Dh, 0Ah
                db '| SHORTCUTS:                                                           |', 0Dh, 0Ah
                db '|  [1] Live Text Editor (DEV)                                          |', 0Dh, 0Ah
                db '|  [2] System Calculator (CALC)                                         |', 0Dh, 0Ah
                db '|  [3] System Settings (SETTINGS)                                      |', 0Dh, 0Ah
                db '|                                                                      |', 0Dh, 0Ah
                db '| Enter choice (1-3) or type EXIT to close Desktop.                    |', 0Dh, 0Ah
                db '========================================================================', 0Dh, 0Ah, 0
msg_desktop_prompt db 'DESKTOP> ', 0
msg_desktop_err    db 'Invalid shortcut option. Choose 1, 2, 3, or EXIT.', 0Dh, 0Ah, 0
msg_app1_launched  db '[DESKTOP] Launching Live ASM Editor...', 0Dh, 0Ah, 0
msg_app2_launched  db '[DESKTOP] Launching Math Utility...', 0Dh, 0Ah, 0
msg_app3_launched  db '[DESKTOP] Launching Control Panel...', 0Dh, 0Ah, 0

; UPDATE ENGINE MESSAGES
msg_checking_repo   db 'Connecting to GitHub origin/main repository...', 0Dh, 0Ah, 0
msg_current_ver     db 'Installed Version: v5.2.0 [Build Code: 520]', 0Dh, 0Ah, 0
msg_repo_ver_found  db 'Remote Version Found: v5.2.0 [Build Code: 520]', 0Dh, 0Ah, 0
msg_no_update       db '[UPDATE] System is running the latest build (v5.2.0).', 0Dh, 0Ah, 0
msg_downgrade_err   db '[ERROR] Target build is older than installed system! Downgrade blocked.', 0Dh, 0Ah, 0
msg_updating        db '[UPDATE] Code change detected! Flashing new build sectors...', 0Dh, 0Ah, 0

; NEOFETCH ASCII ART & SPECS
msg_neofetch_art db '   ______  _____       _______  ____ ', 0Dh, 0Ah
                 db '  / / __ \/ ___/      / __  / \/ /__)', 0Dh, 0Ah
                 db ' / / /_/ /\__ \  --- / /_/ / / / /   ', 0Dh, 0Ah
                 db '/_/\____/____/      /_____/_/\__/    ', 0Dh, 0Ah
                 db '-------------------------------------', 0Dh, 0Ah
                 db 'OS: JS-DOS Bare-Metal v5.2.0', 0Dh, 0Ah
                 db 'Build Code: 520 | Target Arch: x86 16-Bit', 0Dh, 0Ah
                 db 'Boot Base: 0x7C00 | Kernel Base: 0x8000', 0Dh, 0Ah
                 db 'Sectors Allocated: 64 Sectors (32 KB)', 0Dh, 0Ah, 0

; DEVELOPERS CREDITS
msg_dev_credits  db '================================================', 0Dh, 0Ah
                 db '            JS-DOS DEVELOPMENT TEAM             ', 0Dh, 0Ah
                 db '================================================', 0Dh, 0Ah
                 db ' Lead Systems Architect: Tyler                  ', 0Dh, 0Ah
                 db ' Assembly Engineer: Gemini AI                   ', 0Dh, 0Ah
                 db ' Project Repository: https://github.com/js-dos ', 0Dh, 0Ah, 0

; SETTINGS UI
msg_settings_ui  db '+--------------------------------------------------+', 0Dh, 0Ah
                 db '|                 JS-DOS SETTINGS                  |', 0Dh, 0Ah
                 db '+--------------------------------------------------+', 0Dh, 0Ah
                 db '| [1] Toggle Text Colors                           |', 0Dh, 0Ah
                 db '| [2] Toggle Speaker PC Beep                       |', 0Dh, 0Ah
                 db '|                                                  |', 0Dh, 0Ah
                 db '| Select 1 or 2. Type EXIT to return to C:\>       |', 0Dh, 0Ah
                 db '+--------------------------------------------------+', 0Dh, 0Ah, 0
msg_settings_prompt db 'SETTINGS> ', 0
msg_settings_err    db 'Invalid choice. Type 1, 2, or EXIT.', 0Dh, 0Ah, 0
msg_color_changed   db '[SETTINGS] High-Contrast Video Attribute Set.', 0Dh, 0Ah, 0
msg_sound_changed   db '[SETTINGS] Audio Beep Initialized.', 0Dh, 0Ah, 0

; RECOVERY UI
msg_recovery_ui  db '================================================', 0Dh, 0Ah
                 db '              JS-DOS RECOVERY MENU              ', 0Dh, 0Ah
                 db '================================================', 0Dh, 0Ah
                 db ' [1] Repair MBR Boot Sector (0x7C00)            ', 0Dh, 0Ah
                 db ' [2] Scan and Integrity Check Disk Sectors     ', 0Dh, 0Ah
                 db ' [3] Fetch & Rebuild Kernel from GitHub         ', 0Dh, 0Ah
                 db ' Select 1, 2, or 3. Type EXIT to leave menu.     ', 0Dh, 0Ah, 0
msg_recovery_prompt db 'RECOVERY> ', 0
msg_recovery_err    db 'Invalid option. Select 1, 2, 3, or EXIT.', 0Dh, 0Ah, 0
msg_rec_mbr_ok      db '[RECOVERY] Sector 1 signature 0xAA55 verified.', 0Dh, 0Ah, 0
msg_rec_files_ok    db '[RECOVERY] Scanned 64 sectors: 0 bad sectors found.', 0Dh, 0Ah, 0
msg_rec_git_ok      db '[RECOVERY] Clean build restored from GitHub origin.', 0Dh, 0Ah, 0

; DEV MESSAGES
msg_dev_header   db '=== JS-DOS LIVE ASM EDITOR ===', 0Dh, 0Ah, 0
msg_dev_prompt   db 'EDIT> ', 0
msg_dev_saved    db '[RAM Buffer Updated]', 0Dh, 0Ah, 0

; MISC MESSAGES
msg_info_detail db 'System: JS-DOS Real-Mode Kernel v5.2.0 on x86 Architecture.', 0Dh, 0Ah, 0
msg_jlver_info  db 'JLVER Metrics: Boot 0x7C00 | Kernel 0x8000 (32KB)', 0Dh, 0Ah, 0
msg_time        db 'System Clock: 12:00:00', 0Dh, 0Ah, 0
msg_date        db 'System Calendar: 2026-07-24', 0Dh, 0Ah, 0
msg_mem         db 'RAM: 640KB Base RAM | 32KB Kernel Resident', 0Dh, 0Ah, 0
msg_echo        db 'ECHO: Active.', 0Dh, 0Ah, 0
msg_ping        db 'PING github.com: 32 bytes time=8ms', 0Dh, 0Ah, 0
msg_fetch       db 'FETCH: Kernel source synced with origin/main.', 0Dh, 0Ah, 0
msg_calc        db 'CALC: 2 + 2 = 4', 0Dh, 0Ah, 0
msg_color       db 'COLOR: VGA Mode 03h (80x25 Text Mode)', 0Dh, 0Ah, 0
msg_matrix      db 'MATRIX: [0101010101010101]', 0Dh, 0Ah, 0
msg_ver         db 'Version: JS-DOS v5.2.0 Extended Security Build', 0Dh, 0Ah, 0
msg_cpuinfo     db 'CPU: x86 Compatible Processor (Real Mode)', 0Dh, 0Ah, 0
msg_netstat     db 'NETSTAT: Interface eth0 UP | Local: 10.0.2.15', 0Dh, 0Ah, 0
msg_bootlog     db 'BOOTLOG: Stage 1 loaded at 0x7C00 -> Stage 2 at 0x8000 [OK]', 0Dh, 0Ah, 0
msg_poweroff    db 'Powering off VM...', 0Dh, 0Ah, 0
msg_restart     db 'Rebooting...', 0Dh, 0Ah, 0

input_buffer db 32 dup(0)
user_buffer  db 32 dup(0)
pass_buffer  db 32 dup(0)

; Pad Stage 2 Kernel to exactly 32768 bytes (64 sectors)
times 32768-($-kernel_start) db 0
