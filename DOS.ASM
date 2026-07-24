do_update:
    mov si, msg_checking_repo
    call print_string

    mov si, msg_current_ver
    call print_string

    mov si, msg_repo_ver_found
    call print_string

    mov ax, [SYS_VERSION_CODE]
    cmp ax, 530                 ; Compare local version against remote server (530 = v5.3.0)
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
    
    ; Perform the version upgrade in RAM
    mov word [SYS_VERSION_CODE], 530
    mov byte [SYS_VERSION_MAJOR], 5
    mov byte [SYS_VERSION_MINOR], 3
    
    mov si, msg_update_success
    call print_string
    jmp main_loop
