INCLUDE	"gbhw.inc"

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
    ld     a, %11011000     ; grey 3=11 (Black)
                ; grey 2=10 (Dark grey)
                ; grey 1=01 (Ligth grey)
                ; grey 0=00 (Transparent)
    ld    [rBGP], a
    ld    [rOBP0], a         ; 48,49 are sprite palettes
                ; set same as background
    ld    [rOBP1], a
    ret
