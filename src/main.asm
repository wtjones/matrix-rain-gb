INCLUDE	"gbhw.inc"
INCLUDE "ibmpc1.inc"

SECTION	"start",ROM0[$0150]

start::
    nop
    ; init the stack pointer
    di
    ld		sp, $FFF4

    ; enable only vblank interrupts
    ld		a, IEF_VBLANK
    ldh		[rIE], a	; load it to the hardware register

    ; standard inits
    sub		a	;	a = 0
    ldh		[rSTAT], a	; init status

    ldh		[rSCY], a
    ldh		[rSCX], a

    ldh		[rLCDC], a	; init LCD to everything off

    call    init
    ei
    ; enable LCD, sprites, bg
    ld      a, LCDCF_ON | LCDCF_BG8000 | LCDCF_OBJON | LCDCF_BGON
    ldh		[rLCDC], a


.loop:
    xor     a
    ld      [tile_command_list_length], a
    call    move_droplets
    call    set_droplets_to_bg
    call    update_tile_fade
    call    wait_vblank
    call    _HRAM               ; start dma
    call    apply_tile_command_list

    jr .loop

draw:
stat:
timer:
serial:
joypad:
    reti


chrset::
    chr_IBMPC1 1,8
