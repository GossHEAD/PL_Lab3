; runtime.asm - low-level I/O functions for StackVM
; Include via: --include runtime.asm

readInt:
    enter 1
    push_int 0
    store_local 0
readInt_loop:
    lio 0
    io_read
    dup
    push_int 0
    cmp_eq
    jnz readInt_eof
    dup
    push_int 10
    cmp_eq
    jnz readInt_check_sep
    dup
    push_int 13
    cmp_eq
    jnz readInt_check_sep
    dup
    push_int 32
    cmp_eq
    jnz readInt_check_sep
    push_int 48
    sub
    load_local 0
    push_int 10
    mul
    add
    store_local 0
    jmp readInt_loop
readInt_check_sep:
    pop
    load_local 0
    push_int 0
    cmp_eq
    jnz readInt_loop
    jmp readInt_ret
readInt_eof:
    pop
readInt_ret:
    load_local 0
    ret 0

writeInt:
    enter 1
    push_int 0
    store_local 0
    load_arg 0
    push_int 0
    cmp_eq
    jnz writeInt_zero
writeInt_push_loop:
    load_arg 0
    push_int 0
    cmp_eq
    jnz writeInt_pop_loop
    load_arg 0
    push_int 10
    mod
    push_int 48
    add
    load_local 0
    inc
    store_local 0
    load_arg 0
    push_int 10
    div
    store_arg 0
    jmp writeInt_push_loop
writeInt_pop_loop:
    load_local 0
    push_int 0
    cmp_eq
    jnz writeInt_end
    lio 1
    io_write
    load_local 0
    dec
    store_local 0
    jmp writeInt_pop_loop
writeInt_zero:
    push_int 48
    lio 1
    io_write
writeInt_end:
    push_none
    ret 1