.include "constants.inc"

.segment "CODE"
.import main 
.export reset_handler
.proc reset_handler
    SEI
    CLD
    LDX #$00
    STX PPUCTRL
    STX PPUMASK

    vblankwait:
        BIT PPUSTATUS
        BPL vblankwait
        JMP main

    LDX #$00
    LDA #$ff
    clear_oam:
        STA $0200,X ; set sprite y-positions off the screen
        INX
        INX
        INX
        INX
        BNE clear_oam
.endproc

; menos queja, mas tolerancia -Wichie