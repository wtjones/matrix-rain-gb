INCLUDE	"gbhw.inc"
INCLUDE "memory.inc"

TILE_FADE_RATE      EQU 16

SECTION "video vars", WRAM0

frame_count:: DS 1
vblank_flag:: DS 1
current_fade_row_offset:: DS 2
current_fade_ptr:: DS 2
current_tile_ptr:: DS 2
current_fade_tile_y:: DS 1

SECTION "video utility", ROM0

wait_vblank::
    ld      hl, vblank_flag
.wait_vblank_loop
    halt
    nop        ;Hardware bug
    ld      a,$0
    cp      [hl]
    jr      z, .wait_vblank_loop
    ld      [hl], a


    ld      a, [frame_count]
    inc     a
    ld      [frame_count], a

  ret


; For use in displaying and initializing sprites
init_dma::
    ld	de, _HRAM
    ld	hl, dmacode
    ld	bc, dmaend-dmacode
    call	mem_CopyVRAM    ; copy when VRAM is available
    ret
dmacode:
    push	af
    ld	a, _RAM/$100        ; bank where OAM DATA is stored
    ldh	[rDMA], a           ; Start DMA
    ld	a, $28              ; 160ns
.dma_wait:
    dec	a
    jr	nz, .dma_wait
    pop	af
    reti
dmaend:


; Sets the colors to normal palette
init_palette::
    ld     a, %11100100     ; grey 3=11 (Black)
                ; grey 2=10 (Dark grey)
                ; grey 1=01 (Ligth grey)
                ; grey 0=00 (Transparent)
    ld    [rBGP], a
    ld    [rOBP0], a         ; 48,49 are sprite palettes
                ; set same as background
    ld    [rOBP1], a
    ret

;Inputs:
; a = tile y
; e = tile x
; d = tile index
;Destroys:
; BC, HL
set_bg_tile::
    ; tile location is _SCRN0 + x + (y * 32)

    ; multiply a by 32, store in bc (works for low y values at least)
    rrca
    rrca
    rrca

    ld      l, a
    and     %11110000
    ld      c, a

    ld      a, l
    and     %00001111
    ld      b, a

    push    de

    ; set the fade buffer for this tile
    ld      hl, fade_buffer
    add     hl, bc      ; hl is now fade_buffer + (y * 32)
    ld      d, 0
    add     hl, de      ; hl is now fade_buffer + x + (y * 32)
    ld      [hl], $FF

    ; set the tile
    ld      hl, _SCRN0
    add     hl, bc      ; hl is now _SCRN0 + (y * 32)

    ld      d, 0
    add     hl, de      ; hl is now _SCRN0 + x + (y * 32)

    pop     de

    ;push    af
    ;di
    lcd_WaitVRAM
    ;pop     af
    ld      [hl], d
    ;ei

    ;ld      [hl], d

    ret


; Loop through a row of the fade buffer to:
;   - decrement the fade value
;   - set the corresponding bg tile change, if appropriate
update_tile_fade::

    ; point hl to tile x = 0, y = current y in the fade buffer
    ; point de to tile x = 0, y = current y in the bg map
    ld      a, [current_fade_tile_y]

     ; multiply a by 32, store in bc (works for low y values at least)
    rrca
    rrca
    rrca

    ld      l, a
    and     %11110000
    ld      c, a

    ld      a, l
    and     %00001111
    ld      b, a        ; bc is now y * 32

    ld      hl, _SCRN0
    add     hl, bc

    push    hl
    pop     de          ; de is now _SCRN0 + (y * 32)

    ld      hl, fade_buffer
    add     hl, bc      ; hl is now fade_buffer + (y * 32)

    ld      c, 20
    inc	    c
    dec     hl
    dec     de
    jr      .skip
.loop
    ld      a, [hl]    ; read the fade buffer for this tile
    cp      0
    jr      z, .skip
    sub     a, TILE_FADE_RATE
    ld      [hl], a

    cp      191
    jr      nz, .skip
    lcd_WaitVRAM
    ld      a, 255
    ld      [de], a     ; set bg tile

.skip
    inc     hl
    inc     de
    dec	    c
    jr      nz,.loop

    ; increment the current y
    ld      a, [current_fade_tile_y]
    inc     a
    cp      SCRN_Y_B
    jr      nz, .skip_reset_y
    xor     a
.skip_reset_y

    ld      [current_fade_tile_y], a
    ret
