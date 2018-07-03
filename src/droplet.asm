INCLUDE "gbhw.inc"

MAX_DROPLETS            EQU 10
INITIAL_SPAWN_SPRITE_Y  EQU 8
IDLE_SPRITE_Y           EQU 0

SECTION "droplet oam vars", WRAM0[$C000]
droplets:: DS 40 * 4                ; buffer of oam data for dma transfer

SECTION "droplet vars", WRAM0
total_droplets:: DS 1
droplet_sprite_x: DS 1
droplet_sprite_y: DS 1
tile: DS 1
spawn_delay: DS 1                   ; countdown timer for next droplet

SECTION "droplet", ROM0

init_droplets::

    ; clear memory
    ld      hl, droplets
    ld      bc, 40 * 4
    ld      a,0
    call    mem_Set

    xor     a
    ld      [total_droplets],a
    ld      [spawn_delay], a
    ret


spawn_droplet::
    ; has the spawn delay reached zero?
    ld      a, [spawn_delay]
    cp      0
    jr      z, .skip_return
    dec     a
    ld      [spawn_delay], a
    ret
.skip_return
    ; reset the spawn delay with a random range
    push    bc
    call    fast_random
    pop     bc

    and     %00000011
    add     16
    ld      [spawn_delay], a

    ; advance to the next idle droplet
    ld      hl, droplets

    ld      c, MAX_DROPLETS
    inc     c
    jr      .skip
.loop
    ; y
    ld      a, [hl]

    cp      IDLE_SPRITE_Y
    jr      nz, .next


    ; found an idle droplet
    ; set y
    ld      [hl], INITIAL_SPAWN_SPRITE_Y


    ; set x to random 0-19 multiplied by 8 to align with tiles
    inc     hl
    push    hl
    push    bc
    call    get_random_sprite_x
    pop     bc
    pop     hl

    ld      [hl], a

    ; tile
    inc     hl

    push    bc
    call    fast_random
    pop     bc

    and     %00001111
    ld      [hl],a

    ; attributes
    inc     hl
    inc     hl

    ld      a, [total_droplets]
    inc     a
    ld      [total_droplets], a
    ret

.next
    inc     hl
    inc     hl
    inc     hl
    inc     hl
.skip
    dec     c
    jr      nz, .loop
    ret


; Move each active droplet down and rotate the tile
; Speed is based on memory position for variety
move_droplets::
    ld      hl, droplets
    ld      c, MAX_DROPLETS
    inc     c
    jp      .skip

.loop

    ; load variables with current record
    ld      a, [hl+]
    ld      [droplet_sprite_y], a
    ld      a, [hl+]
    ld      [droplet_sprite_x], a
    ld      a, [hl]
    ld      [tile], a
    dec     hl
    dec     hl

    ; is the droplet active?
    ld      a, [droplet_sprite_y]
    cp      IDLE_SPRITE_Y
    jp      nz, .droplet_is_active

    inc     hl
    inc     hl
    inc     hl
    inc     hl
    jp      .skip

.droplet_is_active
    ; determine droplet type 0-3
    ld      a,c
    and     %00000011

    jp      z,.droplet_type_0
    cp      1
    jp      z,.droplet_type_1
    cp      2
    jp      z,.droplet_type_2

    ; disable type 3
    jp      .droplet_type_2

; type 3 - move every fourth frame
.droplet_type_3
    ld      a,  [frame_count]
    and     %00000011
    cp      %00000011
    jp      nz, .dont_move
    ld      e, 1
    jp      .inc_y

; type 2 - move two pixels each frame
.droplet_type_2
    ld      e, 2
    jp      .inc_y

; type 1 - move every other frame
.droplet_type_1
    ld      a,  [frame_count]
    and     %00000001           ; is this an even frame?
    jp      nz, .dont_move
    ld      e, 1
    jp      .inc_y

; type 0 - move every frame
.droplet_type_0
    ld      e, 1

.inc_y
    ld      a, [droplet_sprite_y]
    add     e
    ; if we are now offscreen, set the droplet to idle
    cp      a, SCRN_Y + 16   ; carry flag set if 160 > y
    jp      c, .inc_y_set_idle_skip
    ld      a, [total_droplets]
    dec     a
    ld      [total_droplets], a
    ld      a, IDLE_SPRITE_Y
.inc_y_set_idle_skip
    ld      [droplet_sprite_y], a
.dont_move:

    ld      a,  [frame_count]
    and     %00000011
    cp      %00000011
    jp      nz, .dont_cycle_character

    ld      a,  [droplet_sprite_y]
    cp      IDLE_SPRITE_Y               ; is the droplet idle?
    jp      nc, .skip_tile_reset
    push    bc
    call    fast_random
    pop     bc

    and     %00001111   ; only want 0-15
    ld      [tile],a
.skip_tile_reset
    ld      a,  [tile]
    inc     a
    and     %00001111   ; only want 0-15
    ld      [tile], a
.dont_cycle_character

    ; write to droplet
    ld      a, [droplet_sprite_y]
    ld      [hl+], a
    inc     hl
    ld      a, [tile]
    ld      [hl+], a
    inc     hl

.skip

    dec     c
    jp      nz, .loop
    ret


; Write any tile-aligned (with bg tiles) droplets to the bg map.
set_droplets_to_bg::
    ld      hl, droplets
    ld      c, MAX_DROPLETS
    inc     c
    jr      .skip

.loop
     ; load variables with current record
    ld      a, [hl+]
    ld      [droplet_sprite_y], a
    ld      a, [hl+]
    ld      [droplet_sprite_x], a
    ld      a, [hl]
    ld      [tile], a
    dec     hl
    dec     hl

    ;
    ; burn tile to background
    ;

    ; is the droplet active?
    ld      a, [droplet_sprite_y]
    cp      IDLE_SPRITE_Y
    jr      z, .next

    ; adjust to non-OAM coords
    sub     16

    ; does the y coord align to a tile?
    ld      e, a    ; a is destroyed
    ; mod 8
    and     %00000111

    jr      nz, .next

    ld      a, [tile]
    ld      d, a

    ; divide by 8 to get y tile coord (0 - 17)
    ld      a, e
    rrca
    rrca
    rrca

    ; is a > 17?
    ld      e, a
    sub     a, SCRN_Y_B
    jr      nc, .next
    ld      b, e    ; tile y in b

    ; divide sprite x by 8 to get x tile coord (0 - 19)
    ld      a, [droplet_sprite_x]
    call    get_sprite_x_to_tile_x

    ld      e, a

    ; The bg tile will start with first faded state. This is on
    ; the next row, so just add 16.
    ld      a, d
    add     a, 16
    ld      d, a
    ld      a, b

    ; burn current character to tile map
    push    hl
    push    bc
    call    set_bg_tile     ; a = y, e = x, d = tile
    pop     bc
    pop     hl

.next
    inc     hl
    inc     hl
    inc     hl
    inc     hl

.skip
    dec c
    jr	nz, .loop
    ret

