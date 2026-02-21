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
    enter 0
    call in     ; in возвращает значение на стеке
    ret

; === function writeInt (args=1, locals=0) ===
writeInt:
    enter 0
    load_arg 0
    call out
    push_none
    ret

; === function fn_add (args=2, locals=0) ===
fn_add:
    enter 0
    load_arg 0
    load_arg 1
    add
    ret

; === function fn_sub (args=2, locals=0) ===
fn_sub:
    enter 0
    load_arg 0
    load_arg 1
    sub
    ret

; === function fn_mul (args=2, locals=0) ===
fn_mul:
    enter 0
    load_arg 0
    load_arg 1
    mul
    ret

; === function fn_div (args=2, locals=0) ===
fn_div:
    enter 0
    load_arg 0
    load_arg 1
    div
    ret

; === function fn_mod (args=2, locals=0) ===
fn_mod:
    enter 0
    load_arg 0
    load_arg 1
    mod
    ret

; === function calc (args=3, locals=0) ===
; === function calc (args=3, locals=0) ===
calc:
    enter 0
    load_arg 0              ; op
    push_int 43
    cmp_eq
    jnz calc__if_then_2
    jmp calc__if_else_4

calc__if_then_2:
    load_arg 1              ; a
    load_arg 2              ; b
    call fn_add             ; результат от fn_add уже на стеке
    jmp calc__exit_1

calc__if_else_4:
    load_arg 0              ; op
    push_int 45
    cmp_eq
    jnz calc__if_then_5
    jmp calc__if_else_7

calc__if_then_5:
    load_arg 1              ; a
    load_arg 2              ; b
    call fn_sub             ; результат от fn_sub уже на стеке
    jmp calc__exit_1

calc__if_else_7:
    load_arg 0              ; op
    push_int 42
    cmp_eq
    jnz calc__if_then_8
    jmp calc__if_else_10

calc__if_then_8:
    load_arg 1              ; a
    load_arg 2              ; b
    call fn_mul             ; результат от fn_mul уже на стеке
    jmp calc__exit_1

calc__if_else_10:
    load_arg 0              ; op
    push_int 47
    cmp_eq
    jnz calc__if_then_11
    jmp calc__if_else_13

calc__if_then_11:
    load_arg 1              ; a
    load_arg 2              ; b
    call fn_div             ; результат от fn_div уже на стеке
    jmp calc__exit_1

calc__if_else_13:
    load_arg 0              ; op
    push_int 37
    cmp_eq
    jnz calc__if_then_14
    jmp calc__if_else_16

calc__if_then_14:
    load_arg 1              ; a
    load_arg 2              ; b
    call fn_mod             ; результат от fn_mod уже на стеке
    jmp calc__exit_1

calc__if_else_16:
    push_int 0              ; помещаем 0 на стек для else ветки
    jmp calc__exit_1

calc__exit_1:
    ret                     ; возвращаем результат, который уже на стеке

; === function main (args=0, locals=4) ===
main:
    enter 4
    
    call readInt
    store_local 0           ; op
    
    call readInt
    store_local 1           ; a
    
    call readInt
    store_local 2           ; b
    
    load_local 0            ; op
    load_local 1            ; a
    load_local 2            ; b
    call calc
    store_local 3           ; result
    
    load_local 3            ; result
    call writeInt
    
    push_none
    ret