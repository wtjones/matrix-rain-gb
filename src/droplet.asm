INITIAL_DROPLETS   EQU 16

SECTION "droplet vars", WRAM0

droplets:: DS 40 * 4
total_droplets:: DS 1


SECTION "droplet", ROM0

init_droplets::
    ld      a,INITIAL_DROPLETS
    ld      [total_droplets],a
    ld      hl, droplets
    
    ; clear memory
    ld      bc, 40 * 4
    ld      a,0
    call    mem_Set

    ld      hl, droplets
    ld      bc, 0
init_droplets_loop
    
    push bc

  

    ; y
    call    get_random_y

    ld      [hl],a

    ; x - there are 16 columns, so use sprite offset * 10
    inc     hl
    
    push    hl
    ld      e,c
    ld      h,10
    call mul_8b      ; l = e * h
    ld      a,l
    add     8

    pop hl    
    ld      [hl],a


    ; tile
    inc     hl

    call fast_random
    
    ld     a,e
    ld      [hl],a

    ; attributes
    inc hl
    inc hl
        
    pop bc    
    inc bc

    ld      a,[total_droplets]
    cp      c

    jr	nz,init_droplets_loop	;then loop.
    ret			;done


get_random_y

    call fast_random
    
    ld     a,e
    
    push hl
    and     %00001111
    ld      e,a
    ld      h,10
    call mul_8b      ; l now has e * 10
    ld      a,l
    add     16
    
    pop hl

    ret


move_droplets::
    ld      hl, droplets
    ld      bc, 0
    
move_droplets_loop
    
    push bc
    ; y
    

    ; ld      a,  [frame_count]
    ; ld      b,a


.   ; determine droplet type 0-3    
    ld      a,c
    and     %00000011

    jp      z,.droplet_type_0    
    cp      1
    jp      z,.droplet_type_1
    cp      2
    jp      z,.droplet_type_2
    ;jp      .droplet_type_1

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
    ld      a,  [hl]
    add     e
    ld      [hl],a
.dont_move:
        
    ; x
    inc     hl
    

    ; tile
    inc     hl


    ld      a,  [frame_count]
    and     %00000011
    cp      %00000011
    jp      nz, .dont_cycle_character
    ld      a,  [hl]
    inc     a
    ld      [hl],a

.dont_cycle_character
    
    ; attributes
    inc hl
    inc hl


    ; burn current character to tile map

    

    pop bc

    inc bc
    ld      a,[total_droplets]
    cp      c
    ;ld	a,b		;if b or c != 0,
    ;or	c		;
    jr	nz,move_droplets_loop	;then loop.
    ret	




