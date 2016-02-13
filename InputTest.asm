; A Z80 assembler program to test D-pad, Start and other buttons on a Sega Game Gear
;
; See https://github.com/GameGearSamples/InputTest for details


;--( ROM Setup )---------------------------------------------------------------
;
; see http://www.villehelin.com/wla.txt for WLA-DX directives starting with "."

; SDSC tag and GG rom header
.sdsctag 1.2,"InputTestGameGear","Simple Input Demo","SZR"

; WLA-DX banking setup
.memorymap
defaultslot 0
slotsize $8000
slot 0 $0000
.endme

.rombankmap
bankstotal 1
banksize $8000
banks 1
.endro


.enum $c000 export
   satbuf dsb 256      ; sprite attribute table buffer.
   input db            ; input from player (buttons).
.ende

;--( constants )--------------------------------------------------------------------


; Bits for D-Pad und Button input
.equ BUTTON_UP_BIT    0
.equ BUTTON_DOWN_BIT  1
.equ BUTTON_LEFT_BIT  2
.equ BUTTON_RIGHT_BIT 3
.equ BUTTON_1_BIT     4
.equ BUTTON_2_BIT     5

; coors for sprites, if buttons are pressed
.equ buttonUpPosX      65
.equ buttonUpPosY      50
.equ buttonDownPosX    65
.equ buttonDownPosY    60
.equ buttonLeftPosX    60
.equ buttonLeftPosY    55
.equ buttonRightPosX   70
.equ buttonRightPosY   55
.equ button1PosX      175
.equ button1PosY       60
.equ button2PosX      185
.equ button2PosY       50
.equ buttonStartPosX  175
.equ buttonStartPosY   39

;--( main )--------------------------------------------------------------------

.bank 0 slot 0
.org $0000

main:
    di    ; disable interrupts
    im 1  ; interrupt mode 1

    ld sp, $dff0

    call setUpVdpRegisters
    call clearVram
    call initSpriteAttributeTable

    call loadColorPalettes
    call loadTiles
    call printBackgroundTiles

    call turnOnScreen

    
mainLoop:

    call getInput

    ld hl, $3f00 + 0 ; sprite 0 vpos
    call prepareVram

    ld b, %00000001
    ld c, buttonUpPosY
    call updateNextSpritePos

    ld b, %00000010
    ld c, buttonDownPosY
    call updateNextSpritePos

    ld b, %00000100
    ld c, buttonLeftPosY
    call updateNextSpritePos

    ld b, %00001000
    ld c, buttonRightPosY
    call updateNextSpritePos

    ld b, %00010000
    ld c,button1PosY
    call updateNextSpritePos

    ld b, %00100000
    ld c,button2PosY
    call updateNextSpritePos

    ld b, %10000000
    ld c,buttonStartPosY
    call updateNextSpritePos

    jp mainLoop


;--( Subroutines )-------------------------------------------------------------


; getInput

getInput:
    ; start button
    in a,$00
    and %10000000
    ld b, a

    ; other buttons (D-pad, button 1 and 2)
    in a,$dc
    and %00111111
    or b ; add start button bit, if present

    ld (input), a
    ret

; setUpVdpRegisters
;

; VDP initialisation data
VdpData:
.db %00000110 ; Reg  0, display and interrupt mode.
.db $80       ; Reg  1, display and interrupt mode.
.db $ff       ; Reg  2, screen map base adress, $ff => $3800
.db $ff       ; Reg  3, n.a., should always be set to $ff
.db $ff       ; Reg  4, n.a., should always be set to $ff
.db $82       ; Reg  5, base adress for sprite attribute table (!!)
.db $ff       ; Reg  6, base adress for sprite patterns
.db $85       ; Reg  7
.db $ff       ; reg. 8
.db $86       ; reg. 9
.db $ff       ; Reg 10
VdpDataEnd:

setUpVdpRegisters:
    ld hl,VdpData
    ld b,VdpDataEnd-VdpData
    ld c,$bf
    otir
    ret


; clearVram
;
; fill Video RAM with 0s
;
clearVram:
    ; set VRAM write address to 0 by outputting $4000 ORed with $0000
    ld hl, $4000
    call prepareVram

    ; output 16KB of zeroes
    ld bc, $4000    ; Counter for 16KB of VRAM
    clearVramLoop:
        ld a,0      ; Value to write
        out ($be),a ; Output to VRAM address, which is auto-incremented after each write
        dec bc
        ld a,b
        or c
        jp nz,clearVramLoop
    ret


; initSpriteAttributeTable

SpriteAttributeTableInit:

; vpos #0 -- #63
.db 0, 0, 0, 0, 0, 0, 0, $d0
.db 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0

; 64 unused bytes
.db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

; horizontal positions and char codes for sprites
.db buttonUpPosX,   0
.db buttonDownPosX, 0
.db buttonLeftPosX, 0
.db buttonRightPosX, 0
.db button1PosX, 0
.db button2PosX, 0
.db buttonStartPosX, 0


SpriteAttributeTableInitEnd:

initSpriteAttributeTable:
    ld hl, $3f00
    call prepareVram
    ld hl,SpriteAttributeTableInit ; source of data
    ld bc,SpriteAttributeTableInitEnd-SpriteAttributeTableInit  ; Counter for number of bytes to write
    call writeToVram
    ret

; updateNextSpritePos
;
; parameter registers
; b: bit mask to test for next sprite
; c: y-pos of next sprite, if visible

updateNextSpritePos:
    ld a,(input)
    and b
    jp z, updateNextSpritePosOut
    ld c, 0 ; set y pos to 0
    updateNextSpritePosOut:
        ld a, c
        out ($be), a
    ret

; printBackgroundTiles
;
; write background tiles to VRAM
;

backgroundTilemap: .include "assets/backgroundTilemap.inc"
backgroundTilemapEnd:

printBackgroundTiles:
    ld hl, $38cc ; Game Gear Screen has 102 empty cells on top, 204 words, 204 = $cc
                 ; 3 lines, 6 + 20 + 6 tiles, 3*(6+20+6)+6
    call prepareVram
    ld hl,backgroundTilemap
    ld bc,backgroundTilemapEnd-backgroundTilemap
    call writeToVram
    ret


; loadColorPalettes
;
; load color palettes for background image and sprites from assets to memory
; background palette : $c000
; sprites palette    : $c020
;

backgroundPalette: .include "assets/backgroundPalette.inc"
backgroundPaletteEnd:

spritesPalette: .include "assets/spritesPalette.inc"
spritesPaletteEnd:

loadColorPalettes:

    ld hl, $c000 ; background palette => $c000
    call prepareVram
    ld hl,backgroundPalette ; HL: source of data
    ld bc,backgroundPaletteEnd-backgroundPalette  ; BC: counter for number of bytes to write
    call writeToVram

    ld hl, $c020 ; sprites palette => $c020
    call prepareVram
    ld hl,spritesPalette ; HL: source of data
    ld bc,spritesPaletteEnd-spritesPalette  ; BC: Counter for number of bytes to write
    call writeToVram

    ret

; loadTiles
;
; load tiles for background image and sprites from assets to memory
; background tiles : $4000
; sprite tiles     : $6000

backgroundTiles: .include "assets/backgroundTiles.inc"
backgroundTilesEnd:

spriteTiles: .include "assets/spriteTiles.inc"
spriteTilesEnd:

loadTiles:
    ld hl, $4000 ; background tiles => $4000
    call prepareVram
    ld hl,backgroundTiles ; source of data
    ld bc,backgroundTilesEnd-backgroundTiles ; Counter for number of bytes to write
    call writeToVram

    ld hl, $6000 ; sprite tiles => $6000
    call prepareVram
    ld hl,spriteTiles ; source of data
    ld bc,spriteTilesEnd-spriteTiles ; Counter for number of bytes to write
    call writeToVram
    ret

; turnOnScreen
;
turnOnScreen:
    ld a,%11000000
    out ($bf),a
    ld a,$81
    out ($bf),a
    ret

; prepareVram
;
; Set up vdp to receive data at vram address in HL.
;
prepareVram:
    push af
    ld a,l
    out ($bf),a
    ld a,h
    or $40
    out ($bf),a
    pop af
    ret

; writeToVram
;
; Write BC amount of bytes from data source pointed to by HL.
; Tip: Use prepareVram before calling.
;
writeToVram:
    ld a,(hl)
    out ($be),a
    inc hl
    dec bc
    ld a,c
    or b
    jp nz, writeToVram
    ret
