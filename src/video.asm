INCLUDE	"gbhw.inc"
INCLUDE "memory.inc"

TILE_FADE_STATE_0           EQU 15      ; initial - light gray
TILE_FADE_STATE_1           EQU 9       ; dark gray
TILE_FADE_STATE_2           EQU 5       ; dark gray stipple
TILE_FADE_RATE              EQU 2
TILE_FADE_ROW_LENGTH        EQU SCRN_X_B
TILE_COMMAND_LIST_MAX       EQU 50
TILE_COMMAND_LIST_SIZE      EQU 4

SECTION "video vars", WRAM0

frame_count:: DS 1
vblank_flag:: DS 1
current_fade_tile_y:: DS 1
tile_command_list_length:: DS 1     ; offset of the next available record
tile_command_list:: DS TILE_COMMAND_LIST_MAX * TILE_COMMAND_LIST_SIZE
fade_buffer:: DS _SCRN1 - _SCRN0    ; One byte per bg tile to track the fade
                                    ; of each droplet

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
    ld     a, %00011011     ; grey 3=00 (Transparent)
                            ; grey 2=01 (Ligth grey)
                            ; grey 1=10 (Dark grey)
                            ; grey 0=11 (Black)
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
    ld      [hl], TILE_FADE_STATE_0

    ; set the tile
    ld      hl, _SCRN0
    add     hl, bc      ; hl is now _SCRN0 + (y * 32)

    ld      d, 0
    add     hl, de      ; hl is now _SCRN0 + x + (y * 32)

    pop     bc          ; now has original de
    ld      c, b        ; move tile index to c
    ld      b, 0        ; operation is 0 - direct

    push    hl          ; move target bg tile address to de
    pop     de
    call push_tile_command_list

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

    ld      c, TILE_FADE_ROW_LENGTH
    inc	    c
    dec     hl
    dec     de
    jr      .skip
.loop
    ld      a, [hl]    ; read the fade buffer for this tile
    cp      0
    jr      z, .skip
    sub     TILE_FADE_RATE
    jr      nc, .skip_clear_tile
    ; fade overflowed, so set it back to zero and clear the tile
    xor     a
    ld      [hl], a     ; update the fade value
    ld      a, 255
    ld      b, 0        ; operation
    jr      .write_bg
.skip_clear_tile
    ld      [hl], a     ; update the fade value
    cp      TILE_FADE_STATE_1
    jr      z,  .fade_tile
    cp      TILE_FADE_STATE_2
    jr      z,  .fade_tile

    jr      .skip

.fade_tile
    ld      a, 16
    ld      b, 1        ; operation 1 to indicate inc current by 16
.write_bg
    push    hl
    push    bc
    ld      c, a
    call push_tile_command_list
    pop     bc
    pop     hl

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


; Push a bg tile operation into the command list
;
;Inputs:
; de = destination
; b = operation
; c = value
;Destroys:
; BC, HL
push_tile_command_list::
    ; determine offset via length * 4
    ld      a, [tile_command_list_length]

    rlca
    rlca

    push    bc
    ld      b, 0
    ld      c, a

    ld      hl, tile_command_list
    add     hl, bc
    pop     bc

    ; structure:
    ; - dest high
    ; - dest low
    ; - operation
    ; - value

    ld      a, d
    ld      [hl+], a
    ld      a, e
    ld      [hl+], a
    ld      a, b
    ld      [hl+], a
    ld      a, c
    ld      [hl], a

    ld      a, [tile_command_list_length]
    inc     a
    ld      [tile_command_list_length], a

    ret


apply_tile_command_list::

    ld      hl, tile_command_list
    ld      a, [tile_command_list_length]
    ld      c, a

    inc	    c
    jr      .skip
.loop
    ld      a, [hl+]
    ld      d, a        ; dest high byte
    ld      a, [hl+]
    ld      e, a        ; dest low byte
    ld      a, [hl+]    ; condition
    cp      1
    jr      z, .condition_1

.condition_0
    ld      a, [hl+]    ; just write the value
    jr      .write_bg

.condition_1
    ld      a, [hl+]    ; value
    ld      b, a
    ld      a, [de]
    add     a, b        ; add stored value to current gb tile value

.write_bg
    ld      [de], a     ; set bg tile

.skip
    dec	    c
    jr      nz,.loop
    ret


; For the given sprite x coord, return the aligned bg tile x coord.
; If carry flag is set, sprite x does not align.
; Inputs
; A = sprite x coord
; Outputs
; A = tile x
get_sprite_x_to_tile_x::
    sub     8           ; OAM adjustment
    rrca
    rrca
    rrca
    ret