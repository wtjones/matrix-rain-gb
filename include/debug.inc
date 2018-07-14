INCLUDE	"gbhw.inc"

IF      !DEF(DEBUG_ASM)
DEBUG_ASM     SET  1


; Prints a message to the no$gmb / bgb debugger
; Accepts a string as input, see emulator doc for support
; from https://arvid.io/2016/03/12/debug-messages-in-no-gmb-and-bgb/
DBGMSG: MACRO
        ld  d, d
        jr .end\@
        DW $6464
        DW $0000
        DB \1
.end\@:
        ENDM

ASSERT_NOT_BUSY: MACRO
        ld      a,[rSTAT]
        and     STATF_BUSY
        jr      z, .not_busy\@
        DBGMSG "LCD should not be in a busy state. Halting..."
        di
        halt
.not_busy\@:
        ENDM

ENDC    ;DEBUG_ASM