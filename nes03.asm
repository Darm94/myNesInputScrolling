; Only for emulator
.DB "NES", $1A, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.ORG $8000

.DEFINE PPUCTRL  $2000
.DEFINE PPUMASK  $2001
.DEFINE PPUADDR  $2006
.DEFINE PPUDATA  $2007
.DEFINE PPUSCRL  $2005
.DEFINE JOY1     $4016
.DEFINE BUTTONS  $03         

main:
    ; activate NMI + use right nametable for background
    LDA #%10001000
    STA PPUCTRL
    ; enable background rendering
    LDA #%00001000
    STA PPUMASK
    
    ; write to palette (color 0, palette 0)
    LDA #$3F
    STA PPUADDR
    LDA #$00
    STA PPUADDR
    LDA #$14
    STA PPUDATA

    ; now is possible to write just color because of automatic +1
    LDA #$2C
    STA PPUDATA
    
    LDA #$39
    STA PPUDATA
    
    LDA #$28
    STA PPUDATA
    
    ; Write to nametable
    LDA #$20
    STA PPUADDR
    LDA #$00
    STA PPUADDR
    LDA #$01
    STA PPUDATA

loop:
    JMP loop
    
; -----------------------------------------------------------
; NMI: reaging here joypad and scroll moving in one direction
; -----------------------------------------------------------
nmi:
    TAX                       ; pre-amble

    ; (palette: increasing color )
    LDA #$3F
    STA PPUADDR
    LDA #$03
    STA PPUADDR

    INC $00
    LDA $00
    STA PPUDATA

; -------- Reading joypad 1 ($4016) --------
; --------Strobe setting --------
    LDA #$01
    STA JOY1
    STA BUTTONS
    LSR A
    STA JOY1

; ----- Read loop (A,B,Sel,Start,Up,Down,Left,Right) in PageZero $03 ------               
read_loop:

    LDA JOY1
    LSR A                     ; bit0 -> Carry
    ROL BUTTONS                   ; Carry -> bit0 di $03, shift a sinistra
    BCC read_loop
    
; ------Now BUTTONS should have this bits: 0=A 1=B 2=Sel 3=Start 4=Up 5=Down 6=Left 7=Right ------
; -------- Direction check logic (just one for frame and following a priority) --------
; -------- Read Priority is: Right -> Left -> Down -> Up ---------

    LDA $03
    AND #%00000001            ; Right
    BNE go_right
    LDA $03
    AND #%00000010            ; Left
    BNE go_left
    LDA $03
    AND #%00000100            ; Down
    BNE go_down
    LDA $03
    AND #%00001000            ; Up
    BNE go_up
    JMP no_move

go_right:
    INC $01                   ; X++
    JMP no_move
go_left:
    DEC $01                   ; X--
    JMP no_move
go_down:
    INC $02                   ; Y++
    JMP no_move
go_up:
    DEC $02                   ; Y--

; -------- Manage scrolling --------
no_move:

    LDA $01
    STA PPUSCRL               ; updating position at X
    LDA $02
    STA PPUSCRL               ; updating position at Y

    TXA                       ; post-amble
    RTI

irq:
    RTI

.GOTO $FFFA
.DW nmi
.DW main
.DW irq

; table 1: 4k
.INCBIN "chr01.bin"
; table 2: 4k
.INCBIN "chr02.bin"