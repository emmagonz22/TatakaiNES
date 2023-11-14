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

  load_palettes:
    LDA PPUSTATUS     ; REFLECT THE STATE OF VARIOUS FUNCTION INSIDE THE PPU
    LDA #$3F          ; ($3f == 15) Address of first pallete in memory as indexed in memory
    STA PPUADDR       ; Sets the address that the PPU will access when read or writing data
    LDA #$00          ; loads the value 00 in acu
    STA PPUADDR       ; store acu in PPUADDR register to access for the second byte of pallete data
    LDX #$00          ; Sets the index for the loop that will load the pallete data
  loop_load:
    LDA palettes, X   ; Use palettes memory location and add the X to get the byte position
    STA PPUDATA         ; storing  PPU Data register
    INX               ;increase X + 1
    CPX #$20          ; compare
    BNE loop_load     ; Branch to LoadPalettesLoop if zero flag is not 1 else keepgoing down

  load_bg:
    LDA #$00
    STA $2500
    STA $2500
    LDA PPUSTATUS
    LDA #$20
    STA PPUADDR
    LDA #00
    STA PPUADDR
    LDX #$00
   
  loop_bg_1: ;; Looping to #$F0 since 960 bytes / 4 == 240 bytes since the limit that X can handle is 255 for this kind of operation
    LDA background_asm, X
    STA PPUDATA  
    INX
    CPX #$F0         
    BNE loop_bg_1
    LDX #$00
   
  loop_bg_2:
    LDA background_asm+240, X ; Add 240 $F0 since X cant be higher than 255
    STA PPUDATA
    INX
    CPX #$F0
    BNE loop_bg_2
    LDX #$00
  loop_bg_3:
    LDA background_asm+480, X ; Add 480 $F0 since X cant be higher than 255
    STA PPUDATA
    INX
    CPX #$F0         ; check if we've loaded all the data
    BNE loop_bg_3
    LDX #$00 
  loop_bg_4:
    LDA background_asm+720, X ; Add 720 $F0 since X cant be higher than 255
    STA PPUDATA
    INX
    CPX #$F0         ; check if we've loaded all the data
    BNE loop_bg_4
    
  ;  Attribute table
	attribute_table:
    LDA PPUSTATUS
    LDA #$23
    STA PPUADDR
    LDA #$C0
    STA PPUADDR
    LDX #$00 
    
  loop_attribute_table_bg: 
    LDA attribute_table_bg, X 
    STA PPUDATA
    INX
    CPX #$40
    BNE loop_attribute_table_bg


; vblankwait is period of time when the PPU id not accessing graphics (resting) this occurs at the end of each frame
; During this time the cpu can access the PPU's memory and update the graphics
vblankwait:       ; wait for another vblank before continuing 
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever






.endproc



.segment "RODATA" 
  palettes: ; Defining palettes to be used in the whole project
      ; Background data
      .byte $0f, $09, $19, $2C
      .byte $0f, $2D, $3D, $06
      .byte $0f, $2D, $00, $30
      .byte $0f, $2D, $00, $30
      ; Sprite Data
      .byte $0f, $14, $25, $27
      .byte $0f, $14, $25, $27
      .byte $0f, $14, $25, $27
      .byte $0f, $14, $25, $27

background_asm:
	.byte $00,$00,$00,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$f0,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$6c,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$87,$88,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$87,$88,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$87,$88,$00,$00,$00
	.byte $00,$00,$00,$00,$87,$88,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$87,$88,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$f0,$f0,$f0,$f0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$f0,$f0,$f0,$f0,$f0,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$f0,$f0,$f0,$f0,$f0,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$f0,$f0,$f0,$f0,$f0,$00,$00,$00,$1b,$1b,$1b,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $00,$00,$00,$00,$00,$1b,$1b,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$f0,$f0,$f0,$1b,$1b,$1b,$1b,$1b,$f0,$f0,$f0,$1b,$1b,$f0
	.byte $3a,$4c,$3b,$00,$00,$00,$00,$00,$00,$1b,$1b,$00,$00,$00,$00,$00
	.byte $00,$00,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $4a,$4c,$4b,$00,$00,$00,$37,$00,$00,$00,$00,$38,$39,$00,$00,$00
	.byte $00,$00,$35,$36,$f0,$30,$00,$31,$35,$45,$36,$f0,$f0,$f0,$f0,$30
	.byte $4a,$4c,$4b,$f0,$f0,$f0,$47,$f0,$35,$36,$f0,$48,$49,$f0,$f0,$f0
	.byte $00,$70,$4d,$4d,$4f,$4d,$4d,$4f,$5c,$5d,$5c,$4d,$5d,$4f,$4d,$4d
	.byte $4d,$4f,$5c,$5d,$4d,$5d,$4d,$4d,$4d,$4d,$5c,$5c,$4f,$4f,$41,$00
	.byte $00,$71,$61,$51,$53,$52,$62,$52,$53,$53,$53,$52,$62,$61,$53,$61
	.byte $61,$52,$61,$52,$52,$52,$61,$61,$62,$60,$60,$52,$61,$52,$63,$00
	.byte $00,$f0,$00,$00,$f0,$f0,$f0,$9a,$64,$55,$56,$f0,$f0,$f0,$64,$f0
	.byte $9a,$9a,$f0,$f0,$f0,$f0,$00,$f0,$f0,$65,$66,$f0,$f0,$f0,$f0,$f0
	.byte $00,$f0,$f0,$00,$00,$00,$f0,$f0,$f0,$f0,$00,$00,$00,$00,$00,$00
	.byte $f0,$f0,$f0,$f0,$f0,$9a,$f0,$f0,$f0,$55,$56,$f0,$f0,$f0,$f0,$f0
	.byte $00,$f0,$00,$00,$f0,$00,$00,$00,$00,$00,$00,$f0,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $00,$f0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$f0,$00,$00,$00,$00,$00,$00,$00,$f0,$f0,$00,$f0
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $85,$86,$85,$86,$85,$86,$85,$86,$85,$86,$85,$86,$85,$86,$85,$86
	.byte $85,$86,$85,$86,$85,$86,$85,$86,$85,$86,$85,$86,$85,$86,$86,$85
	.byte $83,$81,$83,$82,$83,$84,$80,$84,$84,$83,$80,$83,$84,$82,$81,$82
	.byte $81,$84,$83,$80,$84,$83,$84,$81,$82,$83,$84,$83,$84,$83,$82,$81
	.byte $00,$f0,$00,$f0,$00,$f0,$89,$f0,$00,$00,$8b,$f0,$f0,$f0,$f0,$f0
	.byte $f0,$8a,$f0,$8b,$00,$00,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a
	.byte $2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a
	.byte $2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a
	.byte $2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a
	.byte $2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a
	.byte $2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a
	.byte $2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a
	.byte $2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a
	.byte $ff,$bf,$ef,$f5,$b5,$55,$55,$5d,$ff,$ef,$ff,$5f,$ff,$bf,$fb,$fe
	.byte $ff,$7f,$ff,$7f,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$af,$af,$af,$af,$af,$af,$af,$af
	.byte $55,$55,$55,$55,$55,$55,$55,$55,$05,$05,$05,$05,$05,$05,$05,$05

  attribute_table_bg: ; 0000 0000 ;(2 first bottom right) ;(3, 4 bottom left) ;(5, 6 top right)  ;(7, 8 top left)
    .byte  %11111111, %11111111, %11111111, %11111111, %11111111, %00000000, %00000000, %00000000
    .byte  %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111
    .byte  %11110000, %11110000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .byte  %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .byte  %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
    .byte  %01010000, %01010000, %01010000, %01010000, %01010000, %01010000, %01010000, %01010000
    .byte  %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101
    .byte  %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "graphics.chr"