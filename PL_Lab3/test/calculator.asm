[section _code]
; === entry point ===
_start:
    call main
    hlt

; --- external functions (implemented elsewhere) ---
; extern fn_in
; extern fn_out

; === function readInt (args=0, locals=1) ===
readInt:
    enter 1 ; allocate 1 local slots
    call fn_in ; args=0
    store_local 0 ; result
    jmp readInt__exit_1
readInt__exit_1:
    push_none ; default return value
    ret

; === function writeInt (args=1, locals=0) ===
writeInt:
    enter 0 ; allocate 0 local slots
    load_arg 0 ; n
    call fn_out ; args=1
    pop ; discard expression result
    jmp writeInt__exit_1
writeInt__exit_1:
    push_none ; default return value
    ret

; === function fn_add (args=2, locals=1) ===
fn_add:
    enter 1 ; allocate 1 local slots
    load_arg 0 ; a
    load_arg 1 ; b
    add
    store_local 0 ; result
    jmp fn_add__exit_1
fn_add__exit_1:
    push_none ; default return value
    ret

; === function fn_sub (args=2, locals=1) ===
fn_sub:
    enter 1 ; allocate 1 local slots
    load_arg 0 ; a
    load_arg 1 ; b
    sub
    store_local 0 ; result
    jmp fn_sub__exit_1
fn_sub__exit_1:
    push_none ; default return value
    ret

; === function fn_mul (args=2, locals=1) ===
fn_mul:
    enter 1 ; allocate 1 local slots
    load_arg 0 ; a
    load_arg 1 ; b
    mul
    store_local 0 ; result
    jmp fn_mul__exit_1
fn_mul__exit_1:
    push_none ; default return value
    ret

; === function fn_div (args=2, locals=1) ===
fn_div:
    enter 1 ; allocate 1 local slots
    load_arg 0 ; a
    load_arg 1 ; b
    div
    store_local 0 ; result
    jmp fn_div__exit_1
fn_div__exit_1:
    push_none ; default return value
    ret

; === function fn_mod (args=2, locals=1) ===
fn_mod:
    enter 1 ; allocate 1 local slots
    load_arg 0 ; a
    load_arg 1 ; b
    mod
    store_local 0 ; result
    jmp fn_mod__exit_1
fn_mod__exit_1:
    push_none ; default return value
    ret

; === function calc (args=3, locals=1) ===
calc:
    enter 1 ; allocate 1 local slots
    push_int 0
    store_local 0 ; result
    load_arg 0 ; op
    push_int 43
    cmp_eq
    jnz calc__if_then_2
    jmp calc__if_else_4
calc__if_then_2:
    load_arg 1 ; a
    load_arg 2 ; b
    call fn_add ; args=2
    store_local 0 ; result
    jmp calc__if_merge_3
calc__if_else_4:
    load_arg 0 ; op
    push_int 45
    cmp_eq
    jnz calc__if_then_5
    jmp calc__if_else_7
calc__if_merge_3:
    load_local 0 ; result
    pop ; discard expression result
    jmp calc__exit_1
calc__if_then_5:
    load_arg 1 ; a
    load_arg 2 ; b
    call fn_sub ; args=2
    store_local 0 ; result
    jmp calc__if_merge_6
calc__if_else_7:
    load_arg 0 ; op
    push_int 42
    cmp_eq
    jnz calc__if_then_8
    jmp calc__if_else_10
calc__if_merge_6:
    jmp calc__if_merge_3
calc__if_then_8:
    load_arg 1 ; a
    load_arg 2 ; b
    call fn_mul ; args=2
    store_local 0 ; result
    jmp calc__if_merge_9
calc__if_else_10:
    load_arg 0 ; op
    push_int 47
    cmp_eq
    jnz calc__if_then_11
    jmp calc__if_else_13
calc__if_merge_9:
    jmp calc__if_merge_6
calc__if_then_11:
    load_arg 1 ; a
    load_arg 2 ; b
    call fn_div ; args=2
    store_local 0 ; result
    jmp calc__if_merge_12
calc__if_else_13:
    load_arg 0 ; op
    push_int 37
    cmp_eq
    jnz calc__if_then_14
    jmp calc__if_merge_15
calc__if_merge_12:
    jmp calc__if_merge_9
calc__if_then_14:
    load_arg 1 ; a
    load_arg 2 ; b
    call fn_mod ; args=2
    store_local 0 ; result
    jmp calc__if_merge_15
calc__if_merge_15:
    jmp calc__if_merge_12
calc__exit_1:
    push_none ; default return value
    ret

; === function main (args=0, locals=4) ===
main:
    enter 4 ; allocate 4 local slots
    call readInt ; args=0
    store_local 0 ; op
    call readInt ; args=0
    store_local 1 ; a
    call readInt ; args=0
    store_local 2 ; b
    load_local 0 ; op
    load_local 1 ; a
    load_local 2 ; b
    call calc ; args=3
    store_local 3 ; result
    load_local 3 ; result
    call writeInt ; args=1
    pop ; discard expression result
    jmp main__exit_1
main__exit_1:
    push_none ; default return value
    ret

[section _code]

fn_in:
    lio 0
    io_read
    ret

fn_out:
    load_arg 0
    lio 1
    io_write
    push_none
    ret