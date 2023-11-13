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
  ;LDA #$00
  ;STA $2500
  ;STA $2500
  RTI
.endproc

.import reset_handler

.export main
.proc main

  load_palettes:
    LDA PPUSTATUS     ; REFLECT THE STATE OF VARIOUS FUNCTION INSIDE THE PPU
    LDA #$3f          ; ($3f == 15) Address of first pallete in memory as indexed in memory
    STA PPUADDR       ; Sets the address that the PPU will access when read or writing data
    LDA #$00          ; loads the value 00 in acu
    STA PPUADDR       ; store acu in PPUADDR register to access for the second byte of pallete data
    LDX #$00          ; Sets the index for the loop that will load the pallete data
  loop_load:
    LDA palettes, X   ; Use palettes memory location and add the X to get the byte position
    STA $2007         ; storing  PPU Data register
    INX               ;increase X + 1
    CPX #$20          ; compare if 20 is equal to 32
    BNE loop_load     ; Branch to LoadPalettesLoop if zero flag is not 1 else keepgoing down


  ;LDX #$00
  ; load_sprites:
  ;  LDA chr_data, X 
  ;  STA $0200, X
  ;  INX
  ;  CPX #$10              ; check if we've loaded all the data
  ;  BNE load_sprites




  load_bg:
    LDA $2002
    LDA #$20
    STA $2006
    LDA #00
    STA $2006
    LDX #$00
    ;LDY #$00
  loop_bg_1: ;; Looping to #$F0 since 960 bytes / 4 == 240 bytes since the limit that X can handle is 255 for this kind of operation
    LDA background_asm, X
    STA PPUDATA  ; Save to PPADDRE
    INX
    CPX #$F0         
    BNE loop_bg_1
    ;INY
    ;LDX #$00
    ;CPY #$03
    ;BNE loop_bg
    LDX #$00 ; Reset X to count from 0 to 240
  loop_bg_2:
    LDA background_asm+240, X ; Add 240 $F0 since X cant be higher than 255
    STA PPUDATA
    INX
    CPX #$F0
    BNE loop_bg_2
    LDX #$00 ; Reset X to count from 0 to 240
  loop_bg_3:
    LDA background_asm+480, X ; Add 480 $F0 since X cant be higher than 255
    STA PPUDATA
    INX
    CPX #$F0         ; check if we've loaded all the data
    BNE loop_bg_3 
    LDX #$00  ; Reset X to count from 0 to 240
  loop_bg_4:
    LDA background_asm+720, X ; Add 720 $F0 since X cant be higher than 255
    STA PPUDATA
    INX
    CPX #$F0         ; check if we've loaded all the data
    BNE loop_bg_4
    LDX #$00 ; Reset X to count from 0 to 240
	; finally, attribute table
	;LDA PPUSTATUS
	;LDA #$23
	;STA PPUADDR
	;LDA #$c2
	;STA PPUADDR
	;LDA #%01000000
	;STA PPUDATA

;	LDA PPUSTATUS
;	LDA #$23;
;	STA PPUADDR;
;	LDA #$e0
;	STA PPUADDR;
;	LDA #%00001100
;	STA PPUDATA


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

; mainmenu
; Pause screen
; load_background:
; Load non-interactive elements
; Load 

.segment "RODATA" 
  palettes: ; Defining palettes to be used in the whole project
      ; Background data
      .byte $0f, $14, $15, $21
      .byte $0f, $08, $25, $14
      .byte $0f, $20, $31, $27
      .byte $0f, $12, $12, $20
      ; Sprite Data
      .byte $0f, $14, $25, $27
      .byte $0f, $14, $25, $27
      .byte $0f, $14, $25, $27
      .byte $0f, $14, $25, $27

  ; chr_data:
  ;    .byte $70, $19, $01, $80
  ;    .byte $70, $06, $01, $88
  ;    .byte $78, $07, $01, $80
  ;    .byte $78, $08, $01, $88

    
  background_asm:
    .byte $00,$00,$00,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$60,$60,$60,$60
    .byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
    .byte $00,$00,$00,$00,$00,$00,$f0,$00,$00,$60,$60,$60,$60,$60,$60,$60
    .byte $60,$60,$60,$00,$60,$60,$60,$60,$60,$60,$60,$89,$60,$60,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .byte $60,$60,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$60,$60,$60,$60,$24
    .byte $27,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$60,$60,$60,$60
    .byte $2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b
    .byte $2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b
    .byte $2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b
    .byte $2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b,$2b
    .byte $60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
    .byte $60,$60,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
    .byte $60,$60,$f0,$f0,$f0,$f0,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
    .byte $60,$60,$f0,$f0,$f0,$f0,$f0,$60,$89,$60,$60,$60,$60,$60,$60,$60
    .byte $00,$00,$00,$00,$00,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
    .byte $60,$60,$f0,$f0,$f0,$f0,$f0,$60,$60,$60,$60,$60,$60,$60,$60,$60
    .byte $60,$60,$60,$00,$00,$00,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
    .byte $60,$60,$f0,$f0,$f0,$f0,$f0,$28,$60,$60,$1b,$1b,$1b,$60,$28,$60
    .byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
    .byte $60,$60,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
    .byte $60,$60,$f0,$f0,$f0,$1b,$1b,$1b,$1b,$1b,$f0,$f0,$f0,$1b,$1b,$f0
    .byte $3a,$4c,$3b,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
    .byte $60,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $4a,$4c,$4b,$60,$60,$60,$37,$60,$60,$60,$60,$38,$39,$60,$60,$60
    .byte $60,$f0,$35,$36,$f0,$30,$40,$31,$35,$45,$36,$f0,$f0,$f0,$f0,$30
    .byte $4a,$4c,$4b,$f0,$f0,$f0,$47,$f0,$35,$36,$f0,$48,$49,$f0,$f0,$f0
    .byte $3e,$3e,$3e,$4e,$3e,$3e,$4e,$3e,$3e,$3e,$3e,$3e,$4e,$3e,$3e,$3e
    .byte $4e,$3e,$3e,$4e,$3e,$3e,$3e,$3e,$3e,$3e,$3e,$4e,$3e,$3e,$3e,$3e
    .byte $60,$f0,$f0,$f0,$f0,$9a,$9a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $f0,$f0,$f0,$f0,$f0,$9a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $60,$f0,$f0,$f0,$f0,$f0,$f0,$9a,$f0,$f0,$9a,$f0,$f0,$f0,$f0,$f0
    .byte $9a,$9a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $60,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$00,$00,$00,$00,$00,$00
    .byte $f0,$f0,$f0,$f0,$f0,$9a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $60,$f0,$f0,$f0,$f0,$f0,$00,$00,$00,$00,$00,$f0,$f0,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $60,$f0,$f0,$f0,$f0,$00,$00,$00,$00,$f0,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $f0,$f0,$f0,$f0,$f0,$00,$00,$00,$00,$00,$00,$00,$f0,$f0,$f0,$f0
    .byte $29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29
    .byte $29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29
    .byte $29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29
    .byte $29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29
    .byte $60,$f0,$f0,$00,$00,$00,$00,$00,$00,$00,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $60,$f0,$f0,$f0,$00,$f0,$f0,$f0,$00,$00,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $60,$f0,$f0,$00,$00,$00,$00,$00,$00,$f0,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $f0,$f0,$f0,$f0,$f0,$f0,$00,$00,$00,$f0,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $60,$60,$f0,$f0,$00,$00,$00,$00,$00,$00,$00,$00,$f0,$f0,$f0,$f0
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $60,$60,$f0,$f0,$f0,$f0,$f0,$f0,$00,$00,$00,$00,$00,$00,$00,$00
    .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $60,$60,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$00,$00,$00,$00,$00,$00,$f0
    .byte $f0,$f0,$f0,$f0,$f0,$f0,$00,$00,$00,$f0,$f0,$f0,$f0,$f0,$f0,$f0
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f


.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "graphics.chr"