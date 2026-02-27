[section _code]
_start:
    init_sp 0x30000
    call main
    hlt

readInt:
    enter 1
    push_int 0
    store_local 0
readInt_loop:
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

fn_add:
    enter 0
    load_arg 0
    load_arg 1
    add
    ret 2

fn_sub:
    enter 0
    load_arg 0
    load_arg 1
    sub
    ret 2

fn_mul:
    enter 0
    load_arg 0
    load_arg 1
    mul
    ret 2

fn_div:
    enter 0
    load_arg 0
    load_arg 1
    div
    ret 2

fn_mod:
    enter 0
    load_arg 0
    load_arg 1
    mod
    ret 2

calc:
    enter 0
    load_arg 0
    push_int 1
    cmp_eq
    jnz calc_add
    load_arg 0
    push_int 2
    cmp_eq
    jnz calc_sub
    load_arg 0
    push_int 3
    cmp_eq
    jnz calc_mul
    load_arg 0
    push_int 4
    cmp_eq
    jnz calc_div
    load_arg 0
    push_int 5
    cmp_eq
    jnz calc_mod
    push_int 0
    ret 3
calc_add:
    load_arg 2
    load_arg 1
    call fn_add
    ret 3
calc_sub:
    load_arg 2
    load_arg 1
    call fn_sub
    ret 3
calc_mul:
    load_arg 2
    load_arg 1
    call fn_mul
    ret 3
calc_div:
    load_arg 2
    load_arg 1
    call fn_div
    ret 3
calc_mod:
    load_arg 2
    load_arg 1
    call fn_mod
    ret 3

main:
    enter 4
    call readInt
    store_local 0
    call readInt
    store_local 1
    call readInt
    store_local 2
    load_local 2
    load_local 1
    load_local 0
    call calc
    store_local 3
    load_local 3
    call writeInt
    pop
    push_none
    ret 0