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



  ;LDX #$00                ; Set LDX to 0 to loop over the chr_data and display the background until X != $80
  ; background_loop:
  ;  LDA chr_data, X
  ;  STA $2007
  ;  INX
  ;  CPX #$80              ; check if we've loaded all the data
  ;  BNE background_loop
  LDX #$00
  load_sprites:
    LDA chr_data, X 
    STA $0200, X
    INX
    CPX #$10              ; check if we've loaded all the data
    BNE load_sprites



  LDX #$00
  LDY #$00
  load_bg:
    LDA background_asm, X 
    STA $2007, X
    INX
    CPX #$F0          ; check if we've loaded all the data
    BNE load_bg
    INY
    CPY #$03
    BNE load_bg


	; finally, attribute table
	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$c2
	STA PPUADDR
	LDA #%01000000
	STA PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$e0
	STA PPUADDR
	LDA #%00001100
	STA PPUDATA



  ;;LDX #$00
  ;;LDY #$00
  ;; load_bg:
  ;;  LDA background_asm, X 
  ;;  STA $2000, X

  ;;  LDA PPUSTATUS
  ;;  LDA #$20
  ;;  INX
  ;;  CPX #$F0          ; check if we've loaded all the data
  ;;  BNE load_bg
  ;;  CPY #$04
  ;;  BNE increase_Y
   
  ;; increase_Y:
  ;;  INY
  ;;  LDX #$00 
  ;;  JMP load_bg

  ;; exit_increase:




  ; Write nametables
  
  ;LDA PPUSTATUS
  ;LDA #$22
  ;STA PPUADDR
  ;LDA $6b
  ;STA PPUADDR
  ;LDX $2f  
  ;STX PPUDATA

  ;LDA PPUSTATUS
  ;LDA #$24
  ;STA PPUADDR
  ;LDA $72
  ;STA PPUADDR
  ;LDX $2f  
  ;STX PPUDATA


  ; Attribute tables

  ;LDA PPUSTATUS
  ;LDA #$20
  ;STA PPUADDR
  ;LDA #$F3
  ;STA PPUADDR
  ;LDA #%01000000
  ;STA PPUDATA


  ;LDA PPUSTATUS
  ;LDA #$20
  ;STA PPUADDR
  ;LDA #$F3
  ;STA PPUADDR
  ;LDA #%00001111
  ;STA PPUDATA




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

background_asm:
	.byte $2a,$2a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$60,$60,$60,$60
	.byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $2a,$2a,$f0,$f0,$60,$60,$f0,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$89,$60,$60,$60,$60
	.byte $60,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a
	.byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$00,$00,$f0,$f0,$f0,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$60,$60,$60,$60,$60
	.byte $60,$60,$f0,$f0,$f0,$f0,$f0,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$f0,$f0,$f0,$f0,$f0,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$f0,$f0,$f0,$89,$f0,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$f0,$2a,$2a,$2a,$f0,$2a,$2a,$2a,$2a,$2a,$2a,$60,$60,$60
	.byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$f0,$f0,$f0,$f0,$f0,$60,$60,$60,$60,$60,$60,$2a,$2a,$2a
	.byte $2a,$2a,$2a,$2a,$2a,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$f0,$f0,$f0,$f0,$f0,$60,$89,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$f0,$f0,$f0,$f0,$f0,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$f0,$f0,$f0,$f0,$f0,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$60,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
	.byte $60,$f0,$35,$36,$f0,$30,$40,$31,$35,$45,$36,$f0,$f0,$f0,$f0,$30
	.byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $60,$f0,$3e,$4e,$3e,$3e,$4e,$3e,$3e,$3e,$3e,$3e,$4e,$3e,$3e,$3e
	.byte $4e,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $60,$f0,$f0,$f0,$f0,$9a,$9a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $f0,$f0,$f0,$f0,$f0,$9a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $60,$f0,$f0,$f0,$f0,$f0,$f0,$9a,$f0,$f0,$9a,$f0,$f0,$f0,$f0,$f0
	.byte $9a,$9a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $60,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$9a,$f0
	.byte $f0,$f0,$f0,$f0,$f0,$9a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $60,$f0,$f0,$f0,$f0,$f0,$2a,$2a,$f0,$f0,$f0,$f0,$f0,$2a,$2a,$2a
	.byte $2a,$f0,$2a,$f0,$2a,$f0,$2a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $60,$f0,$f0,$f0,$f0,$2a,$2a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $f0,$f0,$f0,$f0,$f0,$f0,$2a,$f0,$2a,$2a,$2a,$2a,$f0,$f0,$f0,$f0
	.byte $60,$f0,$2a,$2a,$2a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$2a,$f0,$f0,$f0,$f0
	.byte $60,$f0,$2a,$2a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $60,$f0,$f0,$2a,$2a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $60,$f0,$f0,$f0,$2a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $60,$f0,$f0,$f0,$f0,$2a,$2a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $60,$60,$f0,$f0,$f0,$f0,$2a,$2a,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$2a,$2a,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $60,$60,$f0,$f0,$f0,$f0,$f0,$f0,$2a,$2a,$f0,$f0,$f0,$f0,$f0,$2a
	.byte $2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$2a,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $60,$60,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$2a,$2a,$2a,$2a,$2a,$f0
	.byte $f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0
	.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
	.byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f




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

  chr_data:
      .byte $70, $19, $01, $80
      .byte $70, $06, $01, $88
      .byte $78, $07, $01, $80
      .byte $78, $08, $01, $88

  

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "graphics.chr"