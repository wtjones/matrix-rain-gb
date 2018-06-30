RANDOM_SEED            EQU 10
RANDOM_LENGTH          EQU 40

SECTION "random vars", WRAM0

seed:: DS 1
next_random_offset:: DS 1

SECTION "random", ROM0

init_random::
    xor a
    ld [next_random_offset], a
    ld      a, RANDOM_SEED
    ld      [seed],a
    ret

; Output:
;   A - random tile-aligned x coord
; Destroys:
;   BC, HL
get_random_sprite_x::
    ld      hl, random_sprite_x      ; get start of random LUT
    ld      b, 0
    ld      a, [next_random_offset]  ; current offset in LUT
    ld      c, a
    add     hl, bc
    ld      b, [hl]

    ; inc offset
    ld      a, c
    inc     a

    cp      a, RANDOM_LENGTH
    jp      nz, .no_reset
    ld      a, 0
.no_reset
    ld      [next_random_offset], a
    ld      a, b
    ret

; Fast RND (from http://www.z80.info/pseudo-random.txt)
;
; An 8-bit pseudo-random number generator,
; using a similar method to the Spectrum ROM,
; - without the overhead of the Spectrum ROM.
;
; R = random number seed
; an integer in the range [1, 256]
;
; R -> (33*R) mod 257
;
; S = R - 1
;
; Output
;   A - an 8-bit unsigned integer
; Destroys:
;   BC
fast_random::
    ld a, [seed]
    ld b, a

    rrca ; multiply by 32
    rrca
    rrca
    xor $1f

    add a, b
    sbc a, 255 ; carry

    ld [seed], a
    ret


; Table of tile-aligned sprite x values. Two sequences are used to improve
; randomness.
random_sprite_x:
DB $78,$40,$50,$58,$90,$70,$20,$48,$A0,$18,$88,$68,$8,$60,$80,$98,$28,$38,$30,$10
DB $60,$78,$48,$18,$88,$50,$68,$90,$8,$58,$38,$20,$70,$40,$80,$30,$28,$10,$98,$A0
