.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
player_x: .res 1
player_y: .res 1
player_dir: .res 1
timer: .res 1
step: .res 1
anim: .res 1
scroll: .res 1
ppuctrl_settings: .res 1
pad1: .res 1
.exportzp player_x, player_y, pad1

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.import read_controller1

LDA #$00
STA timer

LDA #$00
STA step

LDA #$00
STA anim

.proc nmi_handler
  LDA anim
  CMP #$09
  BEQ reset_anim

  LDA step
  CMP #$03
  BEQ reset_step
  JMP check_time

  reset_step:
    LDA #$00
    STA step
    JMP check_time

  reset_anim:
    LDA #$00
    STA anim


  check_time:
    LDA timer
    CMP #$0a
    BEQ reset_timer
    JMP continue

  reset_timer:
    LDA #$00
    STA timer
    INC step
    INC anim

continue:
  INC timer
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
	LDA #$00



  JSR draw_player

  RTI
.endproc

.import reset_handler

.export main
.proc main
	LDA #239	 
	STA scroll

  ; write a palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR
load_palettes:
  LDA palettes,X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palettes

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


  LDA anim
  CMP #$00 
  BEQ player_moving_left
  CMP #$01 
  BEQ player_moving_right
  CMP #$02 
  BEQ player_jump
  CMP #$03 
  BEQ player_default
  CMP #$04
  BEQ player_dead
  CMP #$05
  BEQ player_jump
  CMP #$06
  BEQ player_attack_right
  CMP #$07
  BEQ player_attack_left
  ; CMP #$08
  ; BEQ player_moving_left
  

  JMP skip_other_sprites

player_moving_left:
  ; Player sprite when moving left
    ; LDX step
    ; LDA #$37
    ; STA $0201
    ; LDA #$38
    ; STA $0205
    ; LDA left_walk_back, X
    ; STA $0209
    ; LDA left_walk_front, X
    ; STA $020d
    ; JMP skip_other_sprites 


player_moving_right:
    LDX step
    LDA #$03
    STA $0201
    LDA #$04
    STA $0205
    LDA right_walk_back, X
    STA $0209
    LDA right_walk_front, X
    STA $020d
    JMP skip_other_sprites  
 


player_jump:
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
  JMP skip_other_sprites

player_dead:
; Set the default sprite
  LDA #$0b
  STA $0201
  LDA #$0c
  STA $0205
  LDA #$1b
  STA $0209
  LDA #$1c
  STA $020d
  JMP skip_other_sprites

player_attack_right:
; Set the default sprite
  LDA #$31
  STA $0201
  LDA #$32
  STA $0205
  LDA #$41
  STA $0209
  LDA #$42
  STA $020d
  JMP skip_other_sprites

player_attack_left:
; Set the default sprite
  LDA #$33
  STA $0201
  LDA #$34
  STA $0205
  LDA #$43
  STA $0209
  LDA #$44
  STA $020d


skip_other_sprites:


  ; store tile locations
  ; top left tile:
  LDA player_y
  STA $0200
  LDA player_x
  STA $0203

  ; top right tile (x + 8):
  LDA player_y
  STA $0204
  LDA player_x
  CLC
  ADC #$08
  STA $0207

  ; bottom left tile (y + 8):
  LDA player_y
  CLC
  ADC #$08
  STA $0208
  LDA player_x
  STA $020b

  ; bottom right tile (x + 8, y + 8)
  LDA player_y
  CLC
  ADC #$08
  STA $020c
  LDA player_x
  CLC
  ADC #$08
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

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
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

right_walk_back:
  .byte $13, $15, $17

right_walk_front:
  .byte $14, $16, $18

left_walk_back:
  .byte $48, $4a, $4c

left_walk_front:
  .byte $47, $49, $4b

.segment "CHR"
.incbin "hollow.chr"
