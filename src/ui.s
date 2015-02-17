

.include "routines/screen.h"
.include "routines/block.h"
.include "routines/math.h"

.include "ui.h"
.include "fptetromones.h"

MODULE Ui

.segment "SHADOW"
	BYTE	screenBuffer, SCREEN_TILE_WIDTH * SCREEN_TILE_HEIGHT
	BYTE	updateBufferOnZero

	WORD	drawNumberPos

.code

.A8
.I16
ROUTINE Init
	MemCopy UiInitialBuffer, screenBuffer

	STZ	updateBufferOnZero

	JSR	SetupScreen

	JSR	DrawLevelNumber
	JSR	DrawStatistics
	JSR	DrawHiScore
	JSR	DrawScore

	.assert * = VBlank, lderror, "Bad flow"


.A8
.I16
ROUTINE VBlank
	LDA	updateBufferOnZero
	IF_ZERO
		; Insert the screenBuffer into mode7 map
		; Uses a loop to insert 32 bytes at a time into the Mode 7 map.
		; I doubt this is possible in address relocation mode.

		LDA	#VMAIN_INCREMENT_LOW | VMAIN_INCREMENT_1
		STA	VMAIN

		LDA	#DMAP_DIRECTION_TO_PPU | DMAP_TRANSFER_1REG
		STA	DMAP0

		LDA	#.lobyte(VMDATAL)
		STA	BBAD0

		LDX	#.loword(screenBuffer)
		LDA	#.bankbyte(screenBuffer)
		STX	A1T0
		STA	A1B0

		REP	#$20
		SEP	#$10
.A16
.I8
		LDA	#SCREEN_UI_ROW * MODE7_TILE_WIDTH + SCREEN_UI_COLUMN
		LDY	#SCREEN_TILE_WIDTH
		LDX	#MDMAEN_DMA0
		STZ	DAS0H

		REPEAT
			STA	VMADD
			STY	DAS0L
			STX	MDMAEN

			ADD	#MODE7_TILE_WIDTH
			CMP	#(SCREEN_UI_ROW + SCREEN_TILE_HEIGHT) * MODE7_TILE_WIDTH + SCREEN_UI_COLUMN
		UNTIL_GE

		SEP	#$20
		REP	#$10

.A8
.I16
		; A is non zero
		STA	updateBufferOnZero
	ENDIF

	RTS



.A8
.I16
ROUTINE DrawLevelNumber
	; y = score
	; tmp = DRAW_LEVEL_COLUMN * SCREEN_TILE_WIDTH + DRAW_LEVEL_ROW
	; for i = 0 to 2
	; 	y, x = y / 10, y % 10
	;	screenBuffer[tmp - i] = y + NUMBER_DIGIT_DELTA
	;	screenBuffer[tmp + 32 - i] = y + NUMBER_DIGIT_DELTA + NUMBER_DIGIT_SECOND_HALF_DELTA
	;
	; updateBufferOnZero = 0

	LDA	#0
	XBA
	LDA	FPTetromones__level
	TAY

	.repeat 2, i
		LDA	#10
		JSR	Math__Divide_U16Y_U8A

		TXA
		ADD	#NUMBER_DIGIT_DELTA
		STA	screenBuffer + DRAW_LEVEL_COLUMN * SCREEN_TILE_WIDTH + DRAW_LEVEL_ROW - i

		ADD	#NUMBER_DIGIT_SECOND_HALF_DELTA	
		STA	screenBuffer + DRAW_LEVEL_COLUMN * SCREEN_TILE_WIDTH + 32 + DRAW_LEVEL_ROW - i
	.endrepeat

	STZ	updateBufferOnZero

	RTS


.A8
.I16
ROUTINE DrawStatistics
	; for i in 0 to N_PIECES
	;	_DrawNumber_3_U16Y(FPTetromones__statistics[i], #(DRAW_STATS_COLUMN + DRAW_STATS_SPACING * i) * SCREEN_TILE_WIDTH + DRAW_STATS_ROW)
	;
	; updateBufferOnZero = 0

	.repeat N_PIECES, i
		LDX	#(DRAW_STATS_COLUMN + DRAW_STATS_SPACING * i) * SCREEN_TILE_WIDTH + DRAW_STATS_ROW
		LDY	FPTetromones__statistics + 2 * i
		JSR	_DrawNumber_3_U16Y
	.endrepeat

	STZ	updateBufferOnZero

	RTS


;; INPUT:
;;	X: Tile position of the top half of least signifigant digit of the number
;;	Y: number to display.
.A8
.I16
ROUTINE _DrawNumber_3_U16Y
	; drawNumberPos = X
	; for i = 0 to 3
	; 	y, x = y / 10, y % 10
	;	screenBuffer[drawNumberPos - i] = y + NUMBER_DIGIT_DELTA
	;	screenBuffer[drawNumberPos + 32 - i] = y + NUMBER_DIGIT_DELTA + NUMBER_DIGIT_SECOND_HALF_DELTA

	STX	drawNumberPos

	.repeat 3, i
		LDA	#10
		JSR	Math__Divide_U16Y_U8A

		TXA
		LDX	drawNumberPos
		ADD	#NUMBER_DIGIT_DELTA
		STA	screenBuffer - i, X

		ADD	#NUMBER_DIGIT_SECOND_HALF_DELTA	
		STA	screenBuffer + 32 - i, X
	.endrepeat

	RTS


.A8
.I16
ROUTINE DrawHiScore
	LDX	#DRAW_HISCORE_COLUMN * SCREEN_TILE_WIDTH + DRAW_SCORE_ROW
	STX	drawNumberPos
	LDXY	FPTetromones__hiScore
	BRA	_DrawNumber_6_U32XY	


.A8
.I16
ROUTINE DrawScore
	LDX	#DRAW_SCORE_COLUMN * SCREEN_TILE_WIDTH + DRAW_SCORE_ROW
	STX	drawNumberPos
	LDXY	FPTetromones__score

	.assert * = _DrawNumber_6_U32XY, lderror, "Bad Flow"


;; Draws a 6 digit 32 bit number at `drawNumberPos` tile.
;; INPUT:
;;	drawNumberPos: Tile position of the top half of least signifigant digit of the number
;;	XY: number to display.
.A8
.I16
ROUTINE _DrawNumber_6_U32XY
	; for i = 0 to 6
	; 	dividend32, a = dividend32 / 10, dividend32 % 10
	;	screenBuffer[drawNumberPos - i] = a + NUMBER_DIGIT_DELTA
	;	screenBuffer[drawNumberPos + 32 - i] = a + NUMBER_DIGIT_DELTA + NUMBER_DIGIT_SECOND_HALF_DELTA
	;
	; updateBufferOnZero = 0

	STXY	Math__dividend32
	TAX

	.repeat 6, i
		LDA	#10
		JSR	Math__Divide_U32_U8A

		LDX	drawNumberPos
		ADD	#NUMBER_DIGIT_DELTA
		STA	screenBuffer - i, X

		ADD	#NUMBER_DIGIT_SECOND_HALF_DELTA	
		STA	screenBuffer + 32 - i, X
	.endrepeat

	STZ	updateBufferOnZero

	RTS


;; Sets up the Screen Registers and loads tiles, maps and palette to PPU
.A8
.I16
ROUTINE SetupScreen
	LDA	#INIDISP_FORCE
	STA	INIDISP

	;; ::SHOULDDO add BG_MODE to Screen_SetVramBaseAndSize::
	;; ::: Will probably have to rename it::
	LDA	#GAME_MODE
	STA	BGMODE

	Screen_SetVramBaseAndSize GAME

	ClearVramLocation		0, MODE7_TILE_WIDTH * MODE7_TILE_HEIGHT * 2
	TransferToVramLocationDataHigh	gameFieldTiles, 0
	TransferToCgramLocation		gameFieldPalette, 0

	; Reset rotation to normal
	LDA	#1

	STZ	M7A
	STA	M7A
	STZ	M7B
	STZ	M7B
	STZ	M7C
	STZ	M7C
	STZ	M7D
	STA	M7D

	LDA	#.lobyte(SCREEN_CENTER_X)
	STA	M7X
	LDA	#.hibyte(SCREEN_CENTER_X)
	STA	M7X
	LDA	#.lobyte(SCREEN_CENTER_Y)
	STA	M7Y
	LDA	#.hibyte(SCREEN_CENTER_Y)
	STA	M7Y

	LDA	#.lobyte(SCREEN_HOFS)
	STA	M7HOFS
	LDA	#.hibyte(SCREEN_HOFS)
	STA	M7HOFS
	LDA	#.lobyte(SCREEN_VOFS)
	STA	M7VOFS
	LDA	#.hibyte(SCREEN_VOFS)
	STA	M7VOFS

	LDA	#TM_BG1
	STA	TM

	RTS


.rodata
LABEL UiInitialBuffer
	.repeat	SCREEN_TILE_HEIGHT, h
		.incbin "resources/game-field.mp7", (SCREEN_UI_ROW + h) * MODE7_TILE_WIDTH + SCREEN_UI_COLUMN, SCREEN_TILE_WIDTH
	.endrepeat
UiInitialBuffer_End:


ENDMODULE

