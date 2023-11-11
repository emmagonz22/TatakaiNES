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
  RTI
.endproc

.import reset_handler

.export main
.proc main


  ;LDX #$00 ; start out at 0
  ; LoadPaletteData: 
  ;  LDA LoadPaletteData, X ; load data from address (PaletteData + the value in x)
  ;  STA $2007 ;write PPU
  ;  INX 
  ;  CPX #$20 ; Compare X to $20 (32 decimal)
  ;  BNE LoadPaletteData  ; Branch to LoadPalettesLoop if zero flag is not 1 else keepgoing down

  load_palettes:
    LDA PPUSTATUS ; REFLECT THE STATE OF VARIOUS FUNCTION INSIDE THE PPU
    LDA #$3f      ; ($3f == 15) Address of first pallete in memory
    STA PPUADDR   ; Sets the address that the PPU will access when read or writing data
    LDA #$00      ; loads the value 00 in acu
    STA PPUADDR   ; store acu in PPUADDR register to access for the second byte of pallete data
    LDX #$00      ; Sets the index for the loop that will load the pallete data
  loop_load:
    LDA palettes, X ; Use palettes memory location and add the X to get the byte position
    STA $2007 ; storing  PPU Data register
    INX ;increase X + 1
    CPX #$20 ; compare if 20 is equal to 32
    BNE loop_load  ; Branch to LoadPalettesLoop if zero flag is not 1 else keepgoing down



  ; write sprite data
  LDA #$70
  STA $0200 ; Y-coord of first sprite
  LDA #$05
  STA $0201 ; tile number of first sprite
  LDA #$00
  STA $0202 ; attributes of first sprite
  LDA #$80
  STA $0203 ; X-coord of first sprite


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
      .byte $0f, $14, $25, $27
      .byte $0f, $14, $25, $27
      .byte $0f, $14, $25, $27
      .byte $0f, $14, $25, $27

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "graphics.chr"