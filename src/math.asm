SECTION "math vars", WRAM0
seed:: DS 1


SECTION "math", ROM0

;Inputs:
;  E, H
;Outputs:
;  HL = E * H
;Destroys:
;  BC

mul_8b::                         ; this routine performs the operation HL=H*E
    ld      d,0                         ; clearing D and L
    ld      l,d
    ld      b,8                         ; we have 8 bits
mul_8b_loop:
    add     hl, hl                      ; advancing a bit
    jp      nc, mul_8b_skip                ; if zero, we skip the addition (jp is used for speed)
    add     hl, de                      ; adding to the product if necessary
mul_8b_skip:
    dec     b
    jr      nz, mul_8b_loop
    ret

; Outputs:
;   HL = HL / D
; Destroys:
;   bc
div_8b::                        ; this routine performs the operation HL=HL/D
    xor     a                   ; clearing the upper 8 bits of AHL
    ld      b, 16               ; the length of the dividend (16 bits)
div_8b_loop:
    add     hl, hl              ; advancing a bit
    rla
    cp      d                   ; checking if the divisor divides the digits chosen (in A)
    jp      c, div_8b_next_bit  ; if not, advancing without subtraction
    sub     d                   ; subtracting the divisor
    inc     l                   ; and setting the next digit of the quotient
div_8b_next_bit:
    dec     b
    jr      nz, div_8b_loop
    ret

;Inputs:
;  A
;Outputs:
;  A = HL mod 10
;  Z flag is set if divisible by 10
;Destroys:
;  HL

mod_10::
    ld      h,a                     ;add nibbles
    rrca
    rrca
    rrca
    rrca
    add     a,h
    adc     a,0                    ;n mod 15 (+1) in both nibbles
    daa
    ld      l,a
    sub     h                      ; Test if quotient is even or odd
    rra
    sbc     a,a
    and     5
    add     a,l
    daa
    and     $0F
    ret
