[section constants]
_str_0:
    .string "done" ; const #0

[section code]
; === function add (args=2, locals=1) ===
add:
    enter 1 ; allocate 1 local slots
    load_arg 0 ; a
    load_arg 1 ; b
    add
    store_local 0 ; result
    jmp add.exit_1
add.exit_1:
    push_none ; default return value
    ret

; === function factorial (args=1, locals=2) ===
factorial:
    enter 2 ; allocate 2 local slots
    push_int 1
    store_local 0 ; result
    push_int 1
    store_local 1 ; i
    jmp factorial.loop.cond_2
factorial.loop.cond_2:
    load_local 1 ; i
    load_arg 0 ; n
    cmp_le
    jnz factorial.loop.body_3
    jmp factorial.loop.exit_4
factorial.loop.body_3:
    load_local 0 ; result
    load_local 1 ; i
    mul
    store_local 0 ; result
    load_local 1 ; i
    push_int 1
    add
    store_local 1 ; i
    jmp factorial.loop.cond_2
factorial.loop.exit_4:
    load_local 0 ; result
    pop ; discard expression result
    jmp factorial.exit_1
factorial.exit_1:
    push_none ; default return value
    ret

; === function main (args=0, locals=5) ===
main:
    enter 5 ; allocate 5 local slots
    push_int 10
    store_local 0 ; x
    push_int 20
    store_local 1 ; y
    load_local 0 ; x
    load_local 1 ; y
    call add ; args=2
    store_local 2 ; z
    load_local 2 ; z
    push_int 25
    cmp_gt
    jnz main.if.then_2
    jmp main.if.else_4
main.if.then_2:
    load_local 2 ; z
    push_int 5
    sub
    store_local 2 ; z
    jmp main.if.merge_3
main.if.else_4:
    load_local 2 ; z
    push_int 5
    add
    store_local 2 ; z
    jmp main.if.merge_3
main.if.merge_3:
    push_int 5
    call factorial ; args=1
    store_local 3 ; f
    push_int 0
    store_local 4 ; i
    jmp main.loop.cond_5
main.loop.cond_5:
    load_local 4 ; i
    push_int 3
    cmp_lt
    jnz main.loop.body_6
    jmp main.loop.exit_7
main.loop.body_6:
    load_local 4 ; i
    push_int 1
    cmp_eq
    jnz main.if.then_8
    jmp main.if.merge_9
main.loop.exit_7:
    push_const #0 ; string
    call print ; args=1
    pop ; discard expression result
    jmp main.exit_1
main.if.then_8:
    jmp main.loop.exit_7
main.if.merge_9:
    load_local 4 ; i
    push_int 1
    add
    store_local 4 ; i
    jmp main.loop.cond_5
main.exit_1:
    push_none ; default return value
    ret

; [section stack] — managed by VM at runtime
