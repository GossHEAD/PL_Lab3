[section _code]
; === entry point ===
_start:
    init_sp 0x30000
    call main
    hlt

; --- external functions (implemented elsewhere) ---
; extern readInt
; extern writeInt

; === function fn_add (args=2, locals=0) ===
fn_add:
    enter 0
    load_arg 0 ; a
    load_arg 1 ; b
    add
    jmp fn_add_exit_1
fn_add_exit_1:
    ret 2

; === function fn_sub (args=2, locals=0) ===
fn_sub:
    enter 0
    load_arg 0 ; a
    load_arg 1 ; b
    sub
    jmp fn_sub_exit_1
fn_sub_exit_1:
    ret 2

; === function fn_mul (args=2, locals=0) ===
fn_mul:
    enter 0
    load_arg 0 ; a
    load_arg 1 ; b
    mul
    jmp fn_mul_exit_1
fn_mul_exit_1:
    ret 2

; === function fn_div (args=2, locals=0) ===
fn_div:
    enter 0
    load_arg 0 ; a
    load_arg 1 ; b
    div
    jmp fn_div_exit_1
fn_div_exit_1:
    ret 2

; === function fn_mod (args=2, locals=0) ===
fn_mod:
    enter 0
    load_arg 0 ; a
    load_arg 1 ; b
    mod
    jmp fn_mod_exit_1
fn_mod_exit_1:
    ret 2

; === function fn_fib (args=1, locals=0) ===
fn_fib:
    enter 0
    load_arg 0 ; n
    push_int 0
    cmp_eq
    jnz fn_fib_if_then_2
    jmp fn_fib_if_else_4
fn_fib_if_then_2:
    push_int 0
    jmp fn_fib_exit_1
fn_fib_if_else_4:
    load_arg 0 ; n
    push_int 1
    cmp_eq
    jnz fn_fib_if_then_5
    jmp fn_fib_if_else_7
fn_fib_if_merge_3:
    jmp fn_fib_exit_1
fn_fib_if_then_5:
    push_int 1
    jmp fn_fib_exit_1
fn_fib_if_else_7:
    load_arg 0 ; n
    push_int 1
    sub
    call fn_fib
    load_arg 0 ; n
    push_int 2
    sub
    call fn_fib
    add
    jmp fn_fib_exit_1
fn_fib_if_merge_6:
    jmp fn_fib_if_merge_3
fn_fib_exit_1:
    ret 1

; === function calc (args=3, locals=0) ===
calc:
    enter 0
    load_arg 0 ; op
    push_int 1
    cmp_eq
    jnz calc_if_then_2
    jmp calc_if_else_4
calc_if_then_2:
    load_arg 2 ; b
    load_arg 1 ; a
    call fn_add
    jmp calc_exit_1
calc_if_else_4:
    load_arg 0 ; op
    push_int 2
    cmp_eq
    jnz calc_if_then_5
    jmp calc_if_else_7
calc_if_merge_3:
    jmp calc_exit_1
calc_if_then_5:
    load_arg 2 ; b
    load_arg 1 ; a
    call fn_sub
    jmp calc_exit_1
calc_if_else_7:
    load_arg 0 ; op
    push_int 3
    cmp_eq
    jnz calc_if_then_8
    jmp calc_if_else_10
calc_if_merge_6:
    jmp calc_if_merge_3
calc_if_then_8:
    load_arg 2 ; b
    load_arg 1 ; a
    call fn_mul
    jmp calc_exit_1
calc_if_else_10:
    load_arg 0 ; op
    push_int 4
    cmp_eq
    jnz calc_if_then_11
    jmp calc_if_else_13
calc_if_merge_9:
    jmp calc_if_merge_6
calc_if_then_11:
    load_arg 2 ; b
    load_arg 1 ; a
    call fn_div
    jmp calc_exit_1
calc_if_else_13:
    load_arg 0 ; op
    push_int 5
    cmp_eq
    jnz calc_if_then_14
    jmp calc_if_else_16
calc_if_merge_12:
    jmp calc_if_merge_9
calc_if_then_14:
    load_arg 2 ; b
    load_arg 1 ; a
    call fn_mod
    jmp calc_exit_1
calc_if_else_16:
    load_arg 0 ; op
    push_int 6
    cmp_eq
    jnz calc_if_then_17
    jmp calc_if_else_19
calc_if_merge_15:
    jmp calc_if_merge_12
calc_if_then_17:
    load_arg 1 ; a
    call fn_fib
    jmp calc_exit_1
calc_if_else_19:
    push_int 0
    jmp calc_exit_1
calc_if_merge_18:
    jmp calc_if_merge_15
calc_exit_1:
    ret 3

; === function main (args=0, locals=4) ===
main:
    enter 4
    call readInt
    store_local 0 ; op
    call readInt
    store_local 1 ; a
    call readInt
    store_local 2 ; b
    load_local 2 ; b
    load_local 1 ; a
    load_local 0 ; op
    call calc
    store_local 3 ; result
    load_local 3 ; result
    call writeInt
    jmp main_exit_1
main_exit_1:
    ret 0

; [section stack] — managed by VM at runtime

; --- included external code ---
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
