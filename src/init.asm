RANDOM_SEED     EQU 10

SECTION "init", ROM0

init::
    call    init_dma
    ld      hl, chrset
    ld      de, $8000    
    ld      bc, 256 * 8
    call    mem_CopyMono

    call    init_palette

    ld     hl, $9800
    ld  bc, 256 * 4
    ld      a, $FF
    call    mem_SetVRAM

    ld      a, RANDOM_SEED
    ld      [seed],a

    call init_droplets
ret


