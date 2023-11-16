.include "constants.inc"

.segment "ZEROPAGE"
.importzp PLAYER_X, PLAYER_Y

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
    
    LDX #$00
    LDA #$FF
    clear_oam:
        STA $0200,X ; set sprite y-positions off the screen
        INX
        INX
        INX
        INX
        BNE clear_oam

    vblankwait2:
        BIT PPUSTATUS
        BPL vblankwait2

    ; initialize zero-page values
    LDA #$80
    STA PLAYER_X
    LDA #$a0
    STA PLAYER_Y
    JMP main


.endproc
