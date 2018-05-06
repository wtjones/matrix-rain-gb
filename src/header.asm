INCLUDE	"gbhw.inc"

SECTION	"ROM_start",ROM0[$0000]

SECTION	"VBlank_IRQ_Jump",ROM0[$0040]
; Vertical Blanking interrupt
    ld  a,$1
	ld  [vblank_flag],a
	

    reti

SECTION	"LCDC_IRQ_Jump",ROM0[$0048]
; LCDC Status interrupt (can be set for H-Blanking interrupt)
    reti

SECTION	"Timer_Overflow_IRQ_Jump",ROM0[$0050]
; Main Timer Overflow interrupt
    ;jp TimerInterrupt
    reti

SECTION	"Serial_IRQ_Jump",ROM0[$0058]
; Serial Transfer Completion interrupt
    reti

SECTION	"Joypad_IRQ_Jump",ROM0[$0060]
; Joypad Button Interrupt?????
    reti




SECTION	"GameBoy_Header_Start",ROM0[$0100]
; begining of Game Boy game header
    nop    
    jp start

    NINTENDO_LOGO

db "GB Test         "	; game name (must be 16 bytes)
db $00,$00,$00			; unused
db $00					; cart type
db $00					; ROM Size (32 k)
db $00					; RAM Size (0 k)
db $00,$00				; maker ID
db $01					; Version     =1
db $DA					; Complement check (Important)
db $ff,$ff				; Cheksum, needs to be calculated!