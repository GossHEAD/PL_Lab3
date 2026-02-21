; ============================================================
; Тестовый листинг для StackVM
; Стековая ВМ, динамическая типизация, 4 банка памяти
; ============================================================

[section constants]
_str_0:
    .string "Hello"     ; const #0
_str_1:
    .string "Result: "  ; const #1

[section data]
global_x: resb 9       ; tagged value (1 tag + 8 payload)
global_y: resb 9

[section code]

; === Тест 1: загрузка констант разных типов ===
test_types:
    enter 0
    push_int 42         ; int
    push_bool 1         ; bool (true)
    push_char 65        ; char 'A'
    push_const #0       ; string "Hello"
    push_none           ; none
    pop                 ; discard none
    pop                 ; discard string
    pop                 ; discard char
    pop                 ; discard bool
    pop                 ; discard int
    push_none
    ret

; === Тест 2: арифметика (стековая) ===
test_arith:
    enter 0
    push_int 10
    push_int 3
    add                 ; 10 + 3 = 13
    push_int 3
    sub                 ; 13 - 3 = 10
    push_int 3
    mul                 ; 10 * 3 = 30
    push_int 3
    div                 ; 30 / 3 = 10
    push_int 3
    mod                 ; 10 % 3 = 1
    neg                 ; -1
    inc                 ; 0
    ret

; === Тест 3: битовые и логические операции ===
test_logic:
    enter 0
    push_int 255
    push_int 15
    bit_and             ; 0xFF & 0x0F = 0x0F
    push_int 240
    bit_or              ; 0x0F | 0xF0 = 0xFF
    bit_not             ; ~0xFF
    push_int 1
    push_int 4
    bit_shl             ; 1 << 4 = 16
    push_bool 1
    push_bool 0
    log_and             ; true && false = false
    push_bool 1
    push_bool 0
    log_or              ; true || false = true
    log_not             ; !true = false
    ret

; === Тест 4: сравнения (результат — bool) ===
test_compare:
    enter 0
    push_int 10
    push_int 20
    cmp_lt              ; 10 < 20 = true
    push_int 5
    push_int 5
    cmp_eq              ; 5 == 5 = true
    push_int 10
    push_int 5
    cmp_gt              ; 10 > 5 = true
    ret

; === Тест 5: локальные переменные и ветвление ===
test_if:
    enter 2             ; 2 локальных слота
    push_int 10
    store_local 0       ; local[0] = 10
    load_local 0
    push_int 5
    cmp_gt              ; local[0] > 5 ?
    jnz .then
    jmp .else
.then:
    push_int 1
    store_local 1       ; local[1] = 1
    jmp .endif
.else:
    push_int 0
    store_local 1       ; local[1] = 0
.endif:
    load_local 1
    ret                 ; return local[1]

; === Тест 6: цикл ===
test_loop:
    enter 2
    push_int 0
    store_local 0       ; i = 0
    push_int 0
    store_local 1       ; sum = 0
.loop_cond:
    load_local 0
    push_int 5
    cmp_lt              ; i < 5 ?
    jz .loop_end
    load_local 1
    load_local 0
    add
    store_local 1       ; sum = sum + i
    load_local 0
    inc
    store_local 0       ; i = i + 1
    jmp .loop_cond
.loop_end:
    load_local 1        ; push sum
    ret                 ; return sum (= 0+1+2+3+4 = 10)

; === Тест 7: вызов функции ===
add_func:
    enter 0             ; no extra locals, 2 args
    load_arg 0          ; arg a
    load_arg 1          ; arg b
    add
    ret

test_call:
    enter 0
    push_int 7          ; arg a
    push_int 3          ; arg b
    call add_func
    ret                 ; returns 10

; === Тест 8: ввод-вывод ===
test_io:
    enter 0
    lio 1               ; select port 1
    push_int 42
    io_write            ; write 42 to port 1
    lio 0               ; select port 0
    io_read             ; read from port 0
    ret

; === Точка входа ===
main:
    enter 0
    push_int 100
    push_int 200
    call add_func       ; add(100, 200)
    ; result 300 on stack
    lio 1
    io_write            ; output result
    halt

; [section stack] — managed by VM at runtime
