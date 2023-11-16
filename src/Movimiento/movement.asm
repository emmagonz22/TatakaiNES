.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE" 
PLAYER_X: .res 1 ; Reserve memory space in the Zeropage fot PLAYER_X and PLAYER_Y
PLAYER_Y: .res 1
player_dir: .res 1
ppuctrl_settings: .res 1
pad1: .res 1
MOVE_RIGHT: .res 1
MOVE_LEFT: .res 1
MOVE_DOWN: .res 1
MOVE_UP: .res 1
CURRENT_JUMP: .res 1
CANT_JUMP: .res 1
.exportzp PLAYER_X, PLAYER_Y, pad1

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.import read_controller1

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  LDA #$00



  ; read controller
	JSR read_controller1

  ; update tiles *after* DMA transfer
	; and after reading controller state
	JSR update_player
  JSR draw_player


	; if yes,
	; Update base nametable
	LDA ppuctrl_settings
	EOR #%00000010 ; flip bit 1 to its opposite
	STA ppuctrl_settings
	STA PPUCTRL



  RTI
.endproc

.import reset_handler
.import draw_objects

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
    LDA #$00
    STA $2500
    STA $2500
    LDA PPUSTATUS
    LDA #$20
    STA PPUADDR
    LDA #$00
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
  STA ppuctrl_settings
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc


.proc update_player
  PHP  ; Start by saving registers,
  PHA  ; as usual.
  TXA
  PHA
  TYA
  PHA

  LDA #03          ; Return player to default position
  STA player_dir

LDX CANT_JUMP
CPX #%1
BEQ player_gravity
jump:
  LDA pad1
  AND #BTN_UP
  BEQ player_gravity
  LDX CURRENT_JUMP
  CPX #$20
  BEQ player_gravity
  DEC PLAYER_Y
  INC CURRENT_JUMP
  LDA #$02          ; Set player_dir to 2 (up)
  STA player_dir
  LDY #$00

  
player_gravity:
  LDX MOVE_DOWN
  CPX #%1
  BEQ skip_reset_jump
  INC PLAYER_Y
  LDX CURRENT_JUMP
  CPX #$20
  BEQ reset_jump
  LDX CANT_JUMP
  CPX #%1
  BEQ reset_jump
  JMP skip_reset_jump
reset_jump:
  LDA #%1
  STA CANT_JUMP
  DEC CURRENT_JUMP
  CPX $00
  BNE reset_jump 
  LDA #%0
  STA CANT_JUMP
  JMP done_checking
skip_reset_jump:


check_left:
  LDA pad1        ; Load button presses
  AND #BTN_LEFT   ; Filter out all but Left
  BEQ check_right ; If result is zero, left not pressed
  DEC PLAYER_X    ; If the branch is not taken, move player left
  LDA #00          ; Set player_dir to 0 (left)
  STA player_dir


check_right:
  LDA pad1
  AND #BTN_RIGHT
  BEQ done_checking
  INC PLAYER_X
  LDA #01          ; Set player_dir to 1 (right)
  STA player_dir



  
done_checking:
  PLA ; Done with updates, restore registers
  TAY ; and return to where we called this
  PLA
  TAX
  PLA
  PLP


detect_ground: ; USe to detect the main ground (Arena for the players to walk in)
  ; Verify Ground 
  LDA PLAYER_Y
  CMP #FLOOR_Y_COOR
  BCS floor_collition_detected

  ; Verify Y Platform 
  LDA PLAYER_Y
  CMP #PLATFORM_OFFSET_Y
  BCS no_collition


  ; Verify X Platform start
  ;Compare X start 
  LDA PLAYER_X
  CMP #PLATFORM_START_X
  BCC no_collition ; less than PLAYER_X < PLATFORM_START_X jump to end
  ; Verify X Platform end
  ;Compare X end 
  LDA PLAYER_X
  CMP #PLATFORM_END_X
  BCC floor_collition_detected ; LEss than PLAYER_X < PLAFORM_END_X
  no_collition:
    ;  No se esta cayendo
    LDA #0
    STA MOVE_DOWN
    JMP end_collition

floor_collition_detected:
  ; Handle collision here
  LDA #1 ; No se esta cayendo
  STA MOVE_DOWN
end_collition:


  RTS
  
.endproc


.proc draw_player

  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; Set the default sprite
  LDA #$01
  STA $0201
  LDA #$02
  STA $0205
  LDA #$11
  STA $0209
  LDA #$12
  STA $020d

  ; Set player character tile attributes (use palette 0)
  LDA #$00
  STA $0202
  STA $0206
  STA $020a
  STA $020e
  player_direction:
    ; Check player direction and update sprite accordingly
    LDA player_dir
    CMP #$00 ; Compare with 0 (left)
    BEQ player_moving_left
    CMP #$01 ; Compare with 1 (right)
    BEQ player_moving_right
    CMP #$02 ; Compare with 2 (up)
    BEQ player_moving_up
    CMP #$03 ; Compare with 3 (default)
    BEQ player_default

  ; Default sprite (no movement)
  JMP skip_other_sprites

player_moving_left:
  ; Player sprite when moving left
  LDA #$03
  STA $0201
  LDA #$04
  STA $0205
  LDA #$13
  STA $0209
  LDA #$14
  STA $020d
  JMP skip_other_sprites

player_moving_right:
  LDX #$00
  load_sprite1:
      LDA right_step1, X
      STA $0200, X
      INX
      CPX #$10
      BNE load_sprite1

  LDX #$00
  load_sprite2:
      LDA right_step2, X
      STA $0200, X
      INX
      CPX #$10
      BNE load_sprite2
  
  LDX #$00
  load_sprite3:
      LDA right_step3, X
      STA $0200, X
      INX
      CPX #$10
      BNE load_sprite3

  JMP skip_other_sprites


player_moving_up:
  ; Player sprite when moving up
  LDA #$09
  STA $0201
  LDA #$0a
  STA $0205
  LDA #$19
  STA $0209
  LDA #$1a
  STA $020d
  JMP skip_other_sprites

player_default:
; Set the default sprite
  LDA #$01
  STA $0201
  LDA #$02
  STA $0205
  LDA #$11
  STA $0209
  LDA #$12
  STA $020d


  



skip_other_sprites:


  ; store tile locations
  ; top left tile:
  LDA PLAYER_Y
   SBC #$40
  STA $0200
  LDA PLAYER_X
 SBC #$40
  STA $0203

  ; top right tile (x + 8):
  LDA PLAYER_Y
   SBC #$40
  STA $0204
  LDA PLAYER_X
  CLC
  ADC #$08
    SBC #$40
  STA $0207

  ; bottom left tile (y + 8):
  LDA PLAYER_Y
  CLC
  ADC #$08
   SBC #$40
  STA $0208
  LDA PLAYER_X
    SBC #$40
  STA $020b

  ; bottom right tile (x + 8, y + 8)
  LDA PLAYER_Y
  CLC
  ADC #$08
   SBC #$40
  STA $020c
  LDA PLAYER_X
  CLC
  ADC #$08
  SBC #$40
  STA $020f

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.segment "RODATA" 
  palettes: ; Defining palettes to be used in the whole project
      ; Background data
      .byte $0f, $09, $19, $2C
      .byte $0f, $2D, $3D, $06
      .byte $0f, $2D, $00, $30
      .byte $0f, $2D, $00, $30
      ; Sprite Data
      .byte $0f, $30, $28, $05
      .byte $0f, $01, $21, $31
      .byte $0f, $06, $16, $26
      .byte $0f, $09, $19, $29
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
	.byte $00,$00,$f0,$f0,$f0,$f0,$f0,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$f0,$00,$f0,$f0
	.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$f0,$f0,$f0,$00,$00,$00,$00,$00,$00,$00,$1b,$1b,$1b,$1b
	.byte $1b,$1b,$1b,$1b,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$f0,$f0,$f0,$f0,$00,$00,$00,$00,$00,$f0,$f0,$3a,$3b,$f0
	.byte $00,$3a,$3b,$00,$00,$00,$37,$00,$00,$00,$00,$38,$39,$00,$00,$00
	.byte $00,$00,$35,$36,$f0,$30,$00,$31,$35,$45,$36,$f0,$f0,$4a,$4b,$30
	.byte $00,$4a,$4b,$f0,$f0,$f0,$47,$f0,$35,$36,$f0,$48,$49,$f0,$f0,$f0
	.byte $00,$70,$4d,$4d,$4f,$4d,$4d,$4f,$5c,$5d,$5c,$4d,$5d,$4f,$4d,$4d
	.byte $4d,$4f,$5c,$5d,$4d,$5d,$4d,$4d,$4d,$4d,$5c,$5c,$4f,$4f,$41,$00
	.byte $00,$71,$61,$51,$53,$52,$62,$52,$53,$53,$53,$52,$62,$61,$53,$61
	.byte $61,$52,$61,$52,$52,$52,$61,$61,$62,$60,$60,$52,$61,$52,$63,$00
	.byte $00,$f0,$00,$00,$f0,$f0,$f0,$9a,$64,$91,$56,$f0,$f0,$f0,$64,$f0
	.byte $9a,$9a,$f0,$f0,$f0,$f0,$00,$f0,$f0,$65,$66,$f0,$f0,$f0,$f0,$f0
	.byte $00,$f0,$f0,$00,$00,$00,$f0,$f0,$f0,$f0,$00,$00,$00,$00,$00,$00
	.byte $f0,$f0,$f0,$f0,$f0,$9a,$f0,$f0,$f0,$91,$56,$f0,$f0,$f0,$f0,$f0
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
	.byte $ff,$bf,$ef,$ff,$bf,$ff,$ff,$ff,$ff,$ef,$ff,$5f,$ff,$bf,$fb,$fe
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
    .byte  %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101, %01010101
  
  
right_stand:
;   sprite for right standing position
        ;  y     T    P     x
    .byte PLAYER_Y, $01, $00, PLAYER_X
    .byte PLAYER_Y, $02, $00, PLAYER_X
    .byte PLAYER_Y, $11, $00, PLAYER_X
    .byte PLAYER_Y, $12, $00, PLAYER_X

left_stand:
;sprite for left standing position
        ;  y     T    P         x
    .byte PLAYER_Y, $01, %01000000, PLAYER_X
    .byte PLAYER_Y, $02, %01000000, PLAYER_X
    .byte PLAYER_Y, $11, %01000000, PLAYER_X
    .byte PLAYER_Y, $12, %01000000, PLAYER_X
right_step1:
;sprite for right step 1 position
        ;  y     T    P     x
    .byte PLAYER_Y, $03, $00, PLAYER_X
    .byte PLAYER_Y, $04, $00, PLAYER_X
    .byte PLAYER_Y, $13, $00, PLAYER_X
    .byte PLAYER_Y, $14, $00, PLAYER_X
left_step1:
;sprite for left step 1 position
        ;  y     T    P         x
    .byte PLAYER_Y, $03, %01000000, PLAYER_X
    .byte PLAYER_Y, $04, %01000000, PLAYER_X
    .byte PLAYER_Y, $13, %01000000, PLAYER_X
    .byte PLAYER_Y, $14, %01000000, PLAYER_X
    
right_step2:
;sprite for right step 2 position
        ;  y     T    P     x
    .byte PLAYER_Y, $05, $00, PLAYER_X
    .byte PLAYER_Y, $06, $00, PLAYER_X
    .byte PLAYER_Y, $15, $00, PLAYER_X
    .byte PLAYER_Y, $16, $00, PLAYER_X

left_step2:
;sprite for left step 2 position
        ;  y     T    P         x
    .byte PLAYER_Y, $05, %01000000, PLAYER_X
    .byte PLAYER_Y, $06, %01000000, PLAYER_X
    .byte PLAYER_Y, $15, %01000000, PLAYER_X
    .byte PLAYER_Y, $16, %01000000, PLAYER_X

right_step3:
;sprite for right step 3 position
        ;  y     T    P     x
    .byte PLAYER_Y, $07, $00, PLAYER_X
    .byte PLAYER_Y, $08, $00, PLAYER_X
    .byte PLAYER_Y, $17, $00, PLAYER_X
    .byte PLAYER_Y, $18, $00, PLAYER_X

left_step3:
;sprite for left step 3 position
        ;  y     T    P         x
    .byte PLAYER_Y, $07, %01000000, PLAYER_X
    .byte PLAYER_Y, $08, %01000000, PLAYER_X
    .byte PLAYER_Y, $17, %01000000, PLAYER_X
    .byte PLAYER_Y, $18, %01000000, PLAYER_X

right_jump:
;sprite for right jump position
        ;  y     T    P     x
    .byte PLAYER_Y, $09, $00, PLAYER_X
    .byte PLAYER_Y, $0a, $00, PLAYER_X
    .byte PLAYER_Y, $19, $00, PLAYER_X
    .byte PLAYER_Y, $1a, $00, PLAYER_X

left_jump:
;sprite for left jump position
        ;  y     T    P         x
    .byte PLAYER_Y, $09, %01000000, PLAYER_X
    .byte PLAYER_Y, $0a, %01000000, PLAYER_X
    .byte PLAYER_Y, $19, %01000000, PLAYER_X
    .byte PLAYER_Y, $1a, %01000000, PLAYER_X

dead:
;sprite for dead position
        ;  Y     T    P     X
    .byte PLAYER_Y, $0b, $00, PLAYER_X
    .byte PLAYER_Y, $0c, $00, PLAYER_X
    .byte PLAYER_Y, $1b, $00, PLAYER_X
    .byte PLAYER_Y, $1c, $00, PLAYER_X
.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "graphics.chr"

