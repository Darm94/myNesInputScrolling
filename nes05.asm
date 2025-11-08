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
.DEFINE FRAME    $05
.DEFINE THROTTLE $06
.DEFINE THROTTLE_VALUE #$00       
.DEFINE SPEED  $04
.DEFINE SPEED_VALUE #$02


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
    
 ;   ---- Throttle (for slowing scroll movement) and Speed (for fasting scroll movement) init ----
    LDA THROTTLE_VALUE
    STA THROTTLE
    LDA SPEED_VALUE      
    STA SPEED

; ====== LOOP =======================================================================================================================
; ===================================================================================================================================

loop:

;------ SLOWING MOVEMENT PART -----------------------------------------------------------------------------------
;-------  Frame speed waiting to get the movement slower as a start point to get slower using throttling --------
;-------  or to get faster by setting a superior SPEED value                                             --------
;----------------------------------------------------------------------------------------------------------------

WaitFrame:
    LDA FRAME
    BEQ WaitFrame             ; waiting NMI refresh time
    LDA #$00
    STA FRAME                 ; consume frames and reset it to 0

; ------ throttle movemement: do a movement every THROTTLE value number of frames ------
    LDA THROTTLE
    BEQ DoMove                ; if 0 can move
    DEC THROTTLE              ; otherwise decrease Throttle value
    JMP no_move               ; and jump to no_move label

DoMove:
    LDA THROTTLE_VALUE                 ; the value that decide how many loop cicles wait
    STA THROTTLE


; --------READING PART  (Reading joypad 1 ($4016))------------------------------------------------------------
; ------------------------------------------------------------------------------------------------------------

; ----- Strobe setting -----
    LDA #$01
    STA JOY1
    STA BUTTONS
    LSR A
    STA JOY1

; ----- Read loop (A,B,Sel,Start,Up,Down,Left,Right) in PageZero $03 -----              
read_loop:

    LDA JOY1
    LSR A                     ; bit0 -> Carry
    ROL BUTTONS                  
    BCC read_loop
    
; -------- Direction CHECK PART (just one for frame and following a priority) --------------------------------   
; -------- Now BUTTONS should have this bits: 0=A 1=B 2=Sel 3=Start 4=Up 5=Down 6=Left 7=Right     -----------
; -------- Read Priority is: Right -> Left -> Down -> Up                                           -----------
;-------------------------------------------------------------------------------------------------------------

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

;----- my idea here was to use a variable to decide how much change the position based on input direction -----

go_right:                  ; X++
    LDA $01
    CLC
    ADC SPEED
    STA $01
    JMP no_move

go_left:                   ; X--
    LDA $01
    SEC
    SBC SPEED
    STA $01
    JMP no_move

go_down:                   ; Y++
    LDA $02
    CLC
    ADC SPEED
    STA $02
    JMP no_move

go_up:                     ; Y--
    LDA $02
    SEC
    SBC SPEED
    STA $02
    JMP no_move

no_move:
    JMP loop
    
; ======== END LOOP =================================================================================================================
; ===================================================================================================================================


; ----------------------------------------------------------------------------------------------------------
; -------- NMI: scroll moving in one direction (calculated from input during the loop)              --------
; ----------------------------------------------------------------------------------------------------------
nmi:
    INC FRAME                 ; new frame arrived

    TAX                       ; pre-amble

; ---- palette: increasing color ----
    LDA #$3F
    STA PPUADDR
    LDA #$03
    STA PPUADDR

    INC $00
    LDA $00
    STA PPUDATA

; -------- Manage scrolling --------
    LDA $01
    STA PPUSCRL               ; updating position at X
    LDA $02
    STA PPUSCRL               ; updating position at Y

    TXA                       ; post-amble
    RTI

;----------------------------------------------------------------------------------------------------------------
; --- REST OF THE DEFINITIONS -----------------------------------------------------------------------------------
;----------------------------------------------------------------------------------------------------------------

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