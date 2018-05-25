INCLUDE	"gbhw.inc"
INCLUDE "memory.inc"

SECTION "video vars", WRAM0

frame_count:: DS 1
vblank_flag:: DS 1


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
    rlca
    rlca
    rlca
    rlca
    rlca

    ld      l, a
    and     %11110000
    ld      c, a

    ld      a, l
    and     %00001111
    ld      b, a

    ld      hl, _SCRN0
    add     hl, bc      ; hl is now _SCRN0 + (y * 32)

    push    de
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