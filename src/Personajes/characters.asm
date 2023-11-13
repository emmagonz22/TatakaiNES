.include "constants.inc"
.include "header.inc"

.segment "CODE"
.proc irq_handler
  RTI
.endproc


  .proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  LDA #$00
  STA $2500
  STA $2500
  RTI
.endproc

.import reset_handler

.export characters
.proc characters
  
;   write a pallete
LDX PPUSTATUS
LDX #$3f
STX PPUADDR
LDX #$00
STX PPUADDR

load_palettes:
    LDA palettes, X
    STA PPUDATA
    INX
    CPX #$20
    BNE load_palettes
LDX #$00
; Loop to display character in standing position


; Loop to display all of the character's sprites
LDX #$00
load_sprites:
    LDA sprites, X
    STA $0200, X
    INX
    CPX #$B0
    BNE load_sprites


; vblankwait is period of time when the PPU id not accessing graphics (resting) this occurs at the end of each frame
; During this time the cpu can access the PPU's memory and update the graphics
vblankwait: ; wait for another vblank before continuing 
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever

.endproc

.segment "RODATA" ; Defining palettes to be used in the whole project
  palettes: 
      ; Background data
      .byte $0f, $14, $25, $26
      .byte $0f, $11, $25, $27
      .byte $0f, $14, $25, $27
      .byte $0f, $14, $25, $27
      ; Sprite Data
      .byte $0f, $30, $28, $05
      .byte $0f, $01, $21, $31
      .byte $0f, $06, $16, $26
      .byte $0f, $09, $19, $29

  sprites:
    ;   Y = Y position of the sprite 
    ;   X = X position of the sprite 
    ;   T = selected tile of the spritesheet 
    ;   P = selected palette and attributes

;   sprite for right standing position
         ;  y     T    P     x
      .byte $00, $01, $00, $00
      .byte $00, $02, $00, $08
      .byte $08, $11, $00, $00
      .byte $08, $12, $00, $08

  ;sprite for left standing position
         ;  y     T    P         x
      .byte $00, $01, %01000000, $18
      .byte $00, $02, %01000000, $10
      .byte $08, $11, %01000000, $18
      .byte $08, $12, %01000000, $10

  ;sprite for right step 1 position
         ;  y     T    P     x
      .byte $11, $03, $00, $00
      .byte $11, $04, $00, $08
      .byte $19, $13, $00, $00
      .byte $19, $14, $00, $08

  ;sprite for left step 1 position
         ;  y     T    P         x
      .byte $11, $03, %01000000, $18
      .byte $11, $04, %01000000, $10
      .byte $19, $13, %01000000, $18
      .byte $19, $14, %01000000, $10
      

  ;sprite for right step 2 position
         ;  y     T    P     x
      .byte $22, $05, $00, $00
      .byte $22, $06, $00, $08
      .byte $2a, $15, $00, $00
      .byte $2a, $16, $00, $08

  ;sprite for left step 2 position
         ;  y     T    P         x
      .byte $22, $05, %01000000, $18
      .byte $22, $06, %01000000, $10
      .byte $2a, $15, %01000000, $18
      .byte $2a, $16, %01000000, $10

  ;sprite for right step 3 position
         ;  y     T    P     x
      .byte $33, $07, $00, $00
      .byte $33, $08, $00, $08
      .byte $3b, $17, $00, $00
      .byte $3b, $18, $00, $08

  ;sprite for left step 3 position
         ;  y     T    P         x
      .byte $33, $07, %01000000, $18
      .byte $33, $08, %01000000, $10
      .byte $3b, $17, %01000000, $18
      .byte $3b, $18, %01000000, $10

  ;sprite for right jump position
         ;  y     T    P     x
      .byte $44, $09, $00, $00
      .byte $44, $0a, $00, $08
      .byte $4c, $19, $00, $00
      .byte $4c, $1a, $00, $08

  ;sprite for left jump position
         ;  y     T    P         x
      .byte $44, $09, %01000000, $18
      .byte $44, $0a, %01000000, $10
      .byte $4c, $19, %01000000, $18
      .byte $4c, $1a, %01000000, $10

  ;sprite for dead position
         ;  Y     T    P     X
      .byte $55, $0b, $00, $00
      .byte $55, $0c, $00, $08
      .byte $5d, $1b, $00, $00
      .byte $5d, $1c, $00, $08


.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "hollow.chr"
