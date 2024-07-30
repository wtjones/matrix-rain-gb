;*
;* MEMORY.INC - Memory Manipulation Code
;* by GABY. Inspired by Carsten Sorensen & others.
;*
;* V1.0 - Original release
;*

;If all of these are already defined, don't do it again.
INCLUDE	"gbhw.inc"
IF      !DEF(MEMORY1_ASM)
DEF MEMORY1_ASM = 1


MACRO lcd_WaitVRAM
        ld      a,[rSTAT]       ; <---+
        and     STATF_BUSY      ;     |
        jr      nz,@-4          ; ----+
        ENDM

ENDC    ;MEMORY1_ASM