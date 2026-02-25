[section _code]
; === entry point ===
_start:
    call main
    hlt

; === function readInt (args=0) ===
readInt:
    enter 0
    call in
    jmp readInt__exit_1
readInt__exit_1:
    ret 0

; === function writeInt (args=1) ===
; writeInt(n): 1 аргумент, обратный push = без изменений
writeInt:
    enter 0
    load_arg 0 ; n
    call out
    jmp writeInt__exit_1
writeInt__exit_1:
    ret 1

; === function fn_add (args=2: a, b) ===
; Caller пушит: b (первым), a (последним -> ближе к fp)
; load_arg 0 = a (ближайший), load_arg 1 = b
fn_add:
    enter 0
    load_arg 0 ; a
    load_arg 1 ; b
    add
    jmp fn_add__exit_1
fn_add__exit_1:
    ret 2

; === function fn_sub (args=2: a, b) ===
fn_sub:
    enter 0
    load_arg 0 ; a
    load_arg 1 ; b
    sub
    jmp fn_sub__exit_1
fn_sub__exit_1:
    ret 2

; === function fn_mul (args=2: a, b) ===
fn_mul:
    enter 0
    load_arg 0 ; a
    load_arg 1 ; b
    mul
    jmp fn_mul__exit_1
fn_mul__exit_1:
    ret 2

; === function fn_div (args=2: a, b) ===
fn_div:
    enter 0
    load_arg 0 ; a
    load_arg 1 ; b
    div
    jmp fn_div__exit_1
fn_div__exit_1:
    ret 2

; === function fn_mod (args=2: a, b) ===
fn_mod:
    enter 0
    load_arg 0 ; a
    load_arg 1 ; b
    mod
    jmp fn_mod__exit_1
fn_mod__exit_1:
    ret 2

; === function calc (args=3: op, a, b) ===
; Caller пушит: b (первым), a, op (последним -> ближе к fp)
; load_arg 0=op, load_arg 1=a, load_arg 2=b
; При вызове fn_add(a,b): пушим b, потом a (обратный порядок)
calc:
    enter 0
    load_arg 0 ; op
    push_int 43 ; '+'
    cmp_eq
    jnz calc__if_then_2
    jmp calc__if_else_4
calc__if_then_2:
    load_arg 2 ; b  <- push первым (дальний)
    load_arg 1 ; a  <- push вторым (ближний к fp в fn_add)
    call fn_add
    jmp calc__exit_1
calc__if_else_4:
    load_arg 0 ; op
    push_int 45 ; '-'
    cmp_eq
    jnz calc__if_then_5
    jmp calc__if_else_7
calc__if_merge_3:
    jmp calc__exit_1
calc__if_then_5:
    load_arg 2 ; b
    load_arg 1 ; a
    call fn_sub
    jmp calc__exit_1
calc__if_else_7:
    load_arg 0 ; op
    push_int 42 ; '*'
    cmp_eq
    jnz calc__if_then_8
    jmp calc__if_else_10
calc__if_merge_6:
    jmp calc__if_merge_3
calc__if_then_8:
    load_arg 2 ; b
    load_arg 1 ; a
    call fn_mul
    jmp calc__exit_1
calc__if_else_10:
    load_arg 0 ; op
    push_int 47 ; '/'
    cmp_eq
    jnz calc__if_then_11
    jmp calc__if_else_13
calc__if_merge_9:
    jmp calc__if_merge_6
calc__if_then_11:
    load_arg 2 ; b
    load_arg 1 ; a
    call fn_div
    jmp calc__exit_1
calc__if_else_13:
    load_arg 0 ; op
    push_int 37 ; '%'
    cmp_eq
    jnz calc__if_then_14
    jmp calc__if_else_16
calc__if_merge_12:
    jmp calc__if_merge_9
calc__if_then_14:
    load_arg 2 ; b
    load_arg 1 ; a
    call fn_mod
    jmp calc__exit_1
calc__if_else_16:
    push_int 0 ; unknown op -> 0
    jmp calc__exit_1
calc__if_merge_15:
    jmp calc__if_merge_12
calc__exit_1:
    ret 3

; === function main (args=0, locals=4) ===
; local[0]=op, local[1]=a, local[2]=b, local[3]=result
main:
    enter 4
    call readInt
    store_local 0 ; op
    call readInt
    store_local 1 ; a
    call readInt
    store_local 2 ; b
    ; calc(op, a, b): пушим в обратном порядке b, a, op
    load_local 2 ; b   <- push первым (дальний от fp в calc)
    load_local 1 ; a
    load_local 0 ; op  <- push последним (ближний к fp в calc)
    call calc
    store_local 3 ; result
    load_local 3 ; result
    call writeInt  ; writeInt(result): 1 аргумент, push как есть
    pop
    jmp main__exit_1
main__exit_1:
    push_none
    ret 0

; --- runtime ---
in:
    enter 0
    lio 0
    io_read
    jmp in__exit_1
in__exit_1:
    ret 0

out:
    enter 0
    load_arg 0 ; n
    lio 1
    io_write
    push_none
    jmp out__exit_1
out__exit_1:
    ret 1
