[section _code]
; === entry point ===
_start:
    call main
    hlt

; --- external functions (implemented elsewhere) ---
; extern in
; extern out

; === function readInt (args=0, locals=0) ===
readInt:
    enter 0 ; allocate 0 local slots
    call in ; args=0
    jmp readInt__exit_1 ; implicit return
readInt__exit_1:
    ret 0 ; return, clean 0 args

; === function writeInt (args=1, locals=0) ===
writeInt:
    enter 0 ; allocate 0 local slots
    load_arg 0 ; n
    call out ; args=1
    jmp writeInt__exit_1 ; implicit return
writeInt__exit_1:
    ret 1 ; return, clean 1 args

; === function fn_add (args=2, locals=0) ===
fn_add:
    enter 0 ; allocate 0 local slots
    load_arg 0 ; a
    load_arg 1 ; b
    add
    jmp fn_add__exit_1 ; implicit return
fn_add__exit_1:
    ret 2 ; return, clean 2 args

; === function fn_sub (args=2, locals=0) ===
fn_sub:
    enter 0 ; allocate 0 local slots
    load_arg 0 ; a
    load_arg 1 ; b
    sub
    jmp fn_sub__exit_1 ; implicit return
fn_sub__exit_1:
    ret 2 ; return, clean 2 args

; === function fn_mul (args=2, locals=0) ===
fn_mul:
    enter 0 ; allocate 0 local slots
    load_arg 0 ; a
    load_arg 1 ; b
    mul
    jmp fn_mul__exit_1 ; implicit return
fn_mul__exit_1:
    ret 2 ; return, clean 2 args

; === function fn_div (args=2, locals=0) ===
fn_div:
    enter 0 ; allocate 0 local slots
    load_arg 0 ; a
    load_arg 1 ; b
    div
    jmp fn_div__exit_1 ; implicit return
fn_div__exit_1:
    ret 2 ; return, clean 2 args

; === function fn_mod (args=2, locals=0) ===
fn_mod:
    enter 0 ; allocate 0 local slots
    load_arg 0 ; a
    load_arg 1 ; b
    mod
    jmp fn_mod__exit_1 ; implicit return
fn_mod__exit_1:
    ret 2 ; return, clean 2 args

; === function calc (args=3, locals=0) ===
calc:
    enter 0 ; allocate 0 local slots
    load_arg 0 ; op
    push_int 43
    cmp_eq
    jnz calc__if_then_2
    jmp calc__if_else_4
calc__if_then_2:
    load_arg 2 ; b
    load_arg 1 ; a
    call fn_add ; args=2
    jmp calc__exit_1 ; implicit return
calc__if_else_4:
    load_arg 0 ; op
    push_int 45
    cmp_eq
    jnz calc__if_then_5
    jmp calc__if_else_7
calc__if_merge_3:
    jmp calc__exit_1
calc__if_then_5:
    load_arg 2 ; b
    load_arg 1 ; a
    call fn_sub ; args=2
    jmp calc__exit_1 ; implicit return
calc__if_else_7:
    load_arg 0 ; op
    push_int 42
    cmp_eq
    jnz calc__if_then_8
    jmp calc__if_else_10
calc__if_merge_6:
    jmp calc__if_merge_3
calc__if_then_8:
    load_arg 2 ; b
    load_arg 1 ; a
    call fn_mul ; args=2
    jmp calc__exit_1 ; implicit return
calc__if_else_10:
    load_arg 0 ; op
    push_int 47
    cmp_eq
    jnz calc__if_then_11
    jmp calc__if_else_13
calc__if_merge_9:
    jmp calc__if_merge_6
calc__if_then_11:
    load_arg 2 ; b
    load_arg 1 ; a
    call fn_div ; args=2
    jmp calc__exit_1 ; implicit return
calc__if_else_13:
    load_arg 0 ; op
    push_int 37
    cmp_eq
    jnz calc__if_then_14
    jmp calc__if_else_16
calc__if_merge_12:
    jmp calc__if_merge_9
calc__if_then_14:
    load_arg 2 ; b
    load_arg 1 ; a
    call fn_mod ; args=2
    jmp calc__exit_1 ; implicit return
calc__if_else_16:
    push_int 0
    jmp calc__exit_1 ; implicit return
calc__if_merge_15:
    jmp calc__if_merge_12
calc__exit_1:
    ret 3 ; return, clean 3 args

; === function main (args=0, locals=4) ===
main:
    enter 4 ; allocate 4 local slots
    call readInt ; args=0
    store_local 0 ; op
    call readInt ; args=0
    store_local 1 ; a
    call readInt ; args=0
    store_local 2 ; b
    load_local 2 ; b
    load_local 1 ; a
    load_local 0 ; op
    call calc ; args=3
    store_local 3 ; result
    load_local 3 ; result
    call writeInt ; args=1
    jmp main__exit_1 ; implicit return
main__exit_1:
    ret 0 ; return, clean 0 args

; [section stack] — managed by VM at runtime

; --- included external code ---
in:
    enter 0
    lio 0
    io_read         
    ret 0

out:
    enter 0
    load_arg 0      
    lio 1
    io_write        
    push_none       
    ret 1           
