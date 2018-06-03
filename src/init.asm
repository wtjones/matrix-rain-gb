INCLUDE	"gbhw.inc"

RANDOM_SEED         EQU 10
START_TILE_SOURCE   EQU $8E00

SECTION "init", ROM0

init::
    call    init_dma
    ld      hl, chrset
    ld      de, $8000
    ld      bc, 256 * 8
    call    mem_CopyMono
    call    init_tile_fade
    call    init_palette

    ; clear tiles
    ld      hl, $9800
    ld      bc, 256 * 4
    ld      a, $FF
    call    mem_SetVRAM

    ; clear fade buffer
    ld      hl, fade_buffer
    ld      bc, _SCRN1 - _SCRN0
    xor     a
    call    mem_Set

    ; init current_fade_row_offset to zero
    xor     a
    ld      [current_fade_tile_y], a

    ld      a, RANDOM_SEED
    ld      [seed],a
    call    init_droplets
ret


; Copy a row of existing tiles to 4 destination rows with
; this structure;
;   row 0: copy as-is (black with the IBM PC font)
;   row 1: dark grey
;   row 2: light grey
;   row 3: light grey stipple
init_tile_fade
    ; row 0: straight copy
    ld      hl, START_TILE_SOURCE
    ld      de, $8000
    ld      bc, 16 * 16
init_tile_fade_loop

    ld      a, [hl+]
    ld      [de], a
    inc     de


    dec     bc
    ld      a, b  ;if b or c != 0,
    or      c
    jr      nz, init_tile_fade_loop


    ; row 1: dark grey
    ld      hl, START_TILE_SOURCE
    ld      de, $8000 + (16 * 16)
    ld      bc, 16 * 16
init_tile_fade_loop2

    inc     hl
    ld      a, %00000000    ; clear first byte
    ld      [de], a
    inc     de
    dec     bc


    ld      a, [hl+]
    ld      [de], a
    inc     de

    dec     bc

    ld      a,b     ;if b or c != 0,
    or      c
    jr      nz, init_tile_fade_loop2


    ; row 2: light grey
    ld      hl, START_TILE_SOURCE
    ld      de, $8000 + (16 * 16) + (16 * 16)
    ld bc, 16 * 16

init_tile_fade_loop3
    ld      a, [hl+]

    ld      [de], a
    inc     de
    dec     bc

    inc     hl
    ld      a, %00000000    ; clear the 2nd byte
    ld     [de], a
    inc     de

    dec     bc

    ld      a,b     ;if b or c != 0,
    or      c
    jr      nz, init_tile_fade_loop3


    ; row 3: stipple
    ld      hl, START_TILE_SOURCE
    ld      de, $8000 + (16 * 16) + (16 * 16) + (16 * 16)
    ld bc, 16 * 16

init_tile_fade_loop4

    ld      a, c
    and     %00000011
    jr      nz, .init_tile_fade_loop4_odd
    ; even pattern
    ld     a,[hl+]
    and     %10101010
    jr      .set_byte
.init_tile_fade_loop4_odd
    ; odd pattern
    ld     a,[hl+]
    and     %01010101

.set_byte
    ld      [de],a
    inc     de
    dec     bc

    inc     hl
    ld      a, %00000000    ; clear the 2nd byte

    ld     [de], a
    inc     de
    dec     bc

    ld      a,b     ;if b or c != 0,
    or      c
    jr      nz, init_tile_fade_loop4

    ret
