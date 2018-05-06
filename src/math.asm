SECTION "math vars", WRAM0
seed:: DS 1


SECTION "math", ROM0

;Inputs:
;  E, H
;Outputs:
;  L = E * H
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


fast_random::
    push bc
    ld a, [seed]
    ld b, a 

    rrca ; multiply by 32
    rrca
    rrca
    xor $1f

    add a, b
    sbc a, 255 ; carry

    ld [seed], a
    ld      e,a
    pop bc
    ret