; main program
; E0 = X, E1 = temp, E2 = Y, E3 = remainder, E4 = high digit
; F8 input, F9 low digit, FA high digit, FB error, FC done

START:
    PUSH  F8
    POP   E0

; X < 0 ?
    PUSH  E0
    PUSHC 00
    CMP
    POP   E1
    POP   E1
    PUSHC ERROR
    JS

; X < 32 ?
    PUSH  E0
    PUSHC 20
    CMP
    POP   E1
    POP   E1
    PUSHC CASE1
    JS

; X < 64 ?
    PUSH  E0
    PUSHC 40
    CMP
    POP   E1
    POP   E1
    PUSHC CASE2
    JS

CASE3:
; Y = X - 40
    PUSH  E0
    PUSHC 28
    SUB
    POP   E2
    PUSHC OUTPUT
    JUMP

CASE1:
; Y = X + 2X + 5
    PUSH  E0
    PUSH  E0
    SHL
    ADD
    PUSHC 05
    ADD
    POP   E2
    PUSHC OUTPUT
    JUMP

CASE2:
; Y = 2X + 20
    PUSH  E0
    SHL
    PUSHC 14
    ADD
    POP   E2
    PUSHC ERROR
    JS
    PUSHC OUTPUT
    JUMP

OUTPUT:
    PUSHC 00
    POP   FB
    PUSH  E2
    POP   F9
    PUSH  E2
    POP   E3
    PUSHC 00
    POP   E4

HIGH_LOOP:
; count how many 16s are in Y
    PUSH  E3
    PUSHC 10
    CMP
    POP   E1
    POP   E1
    PUSHC HIGH_DONE
    JS

    PUSH  E3
    PUSHC 10
    SUB
    POP   E3
    PUSH  E4
    PUSHC 01
    ADD
    POP   E4
    PUSHC HIGH_LOOP
    JUMP

HIGH_DONE:
    PUSH  E4
    POP   FA
    PUSHC 01
    POP   FC
    PUSHC HALT
    JUMP

ERROR:
    PUSHC 01
    POP   FB
    PUSHC 00
    POP   F9
    PUSHC 00
    POP   FA
    PUSHC 01
    POP   FC
    PUSHC HALT
    JUMP

HALT:
; no halt instruction, stay here
    PUSHC HALT
    JUMP
