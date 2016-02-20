; A Z80 assembler program to test D-pad, Start and other buttons on a Sega Game Gear
;
; See https://github.com/GameGearSamples/InputTest for details


;--( ROM Setup )---------------------------------------------------------------
;
; see http://www.villehelin.com/wla.txt for WLA-DX directives starting with "."

; SDSC tag and GG rom header
.sdsctag 1.2,"ButtonTestGameGear","Simple Input Demo","szr"

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

; coors for sprites in image and checkboxes, if buttons are pressed
;
.equ upImageX        63 ; sprite 0
.equ upImageY        51
.equ upCheckboxX     60 ; sprite 1
.equ upCheckboxY    119

.equ downImageX      63 ; sprite 2 ...
.equ downImageY      60
.equ downCheckboxX   60
.equ downCheckboxY  135

.equ leftImageX      59
.equ leftImageY      56
.equ leftCheckboxX  116
.equ leftCheckboxY  119

.equ rightImageX     69
.equ rightImageY     56
.equ rightCheckboxX 116
.equ rightCheckboxY 135

.equ b1ImageX       174
.equ b1ImageY        60
.equ b1CheckboxX    180
.equ b1CheckboxY    119

.equ b2ImageX       185
.equ b2ImageY        51
.equ b2CheckboxX    180
.equ b2CheckboxY    135

.equ startImageX    175
.equ startImageY     40
.equ startCheckboxX 116
.equ startCheckboxY 151

; bit masks for buttons in input byte
.equ upMask          %00000001
.equ downMask        %00000010
.equ leftMask        %00000100
.equ rightMask       %00001000
.equ allDpadMask     %00001111 ; all direction buttons are pressed
.equ button1Mask     %00010000
.equ button2Mask     %00100000
.equ startButtonMask %10000000


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
    call startSpritePosUpdates

    ; up
    ld b, upMask

    ld c, upImageY
    call updateNextSpritePos

    ld c, upCheckboxY
    call updateNextSpritePos


    ; down
    ld b, downMask

    ld c, downImageY
    call updateNextSpritePos

    ld c, downCheckboxY
    call updateNextSpritePos


    ; left
    ld b, leftMask

    ld c, leftImageY
    call updateNextSpritePos

    ld c, leftCheckboxY
    call updateNextSpritePos


    ; right
    ld b, rightMask

    ld c, rightImageY
    call updateNextSpritePos

    ld c, rightCheckboxY
    call updateNextSpritePos


    ; button 1
    ld b, button1Mask

    ld c, b1ImageY
    call updateNextSpritePos

    ld c, b1CheckboxY
    call updateNextSpritePos


    ; button 2
    ld b, button2Mask

    ld c, b2ImageY
    call updateNextSpritePos

    ld c, b2CheckboxY
    call updateNextSpritePos


    ; start button
    ld b, startButtonMask

    ld c, startImageY
    call updateNextSpritePos

    ld c, startCheckboxY
    call updateNextSpritePos

    jp mainLoop


;--( Subroutines )-------------------------------------------------------------


; getInput
;
; gets input from buttons
;
; start button from port $00
; D-pad an button 1, 2 from port $dc
; stored bitwise in memory adress: input

getInput:
    ; start button
    in a,$00
    and startButtonMask
    ld b, a

    ; other buttons (D-pad, button 1 and 2)
    in a,$dc
    and allDpadMask | button1Mask | button2Mask
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
.db 0, 0, 0, 0, 0, 0, 0, 0
.db 0, 0, 0, 0, 0, 0, $d0, 0
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
.db upImageX,       3
.db upCheckboxX,    7
.db downImageX,     4
.db downCheckboxX,  7
.db leftImageX,     5
.db leftCheckboxX,  7
.db rightImageX,    6
.db rightCheckboxX, 7
.db b1ImageX,       0
.db b1CheckboxX,    7
.db b2ImageX,       1
.db b2CheckboxX,    7
.db startImageX,    2
.db startCheckboxX, 7

SpriteAttributeTableInitEnd:

initSpriteAttributeTable:
    ld hl, $3f00
    call prepareVram
    ld hl,SpriteAttributeTableInit ; source of data
    ld bc,SpriteAttributeTableInitEnd-SpriteAttributeTableInit  ; Counter for number of bytes to write
    call writeToVram
    ret

; startSpritePosUpdates
;
startSpritePosUpdates:
    ld hl, $3f00 + 0 ; sprite 0 vpos
    call prepareVram
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


