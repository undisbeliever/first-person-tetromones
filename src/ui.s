
.include "includes/registers.inc"
.include "routines/screen.h"
.include "routines/block.h"
.include "routines/reset-snes.h"
.include "routines/math.h"

.include "ui.h"
.include "pieces.h"
.include "fptetromones.h"

MODULE Ui

.segment "SHADOW"
	STRUCT 	oamBuffer, OamFormat, 4
	BYTE	updateOamBufferOnZero

	UINT16	mode7Hofs
	UINT16	mode7Vofs

	BYTE	screenBuffer, SCREEN_TILE_WIDTH * SCREEN_TILE_HEIGHT
	BYTE	updateBufferOnZero

	WORD	drawNumberPos
	BYTE	drawPieceRow
	BYTE	drawPieceColumn
	WORD	drawPieceTemp

	SAME_VARIABLE	drawPieceTile, drawNumberPos

.code

.A8
.I16
ROUTINE Init
	MemCopy UiInitialBuffer, screenBuffer

	JSR	SetupScreen

	LDY	SCREEN_CENTER_X
	STY	mode7Hofs
	LDY	SCREEN_CENTER_Y
	STY	mode7Vofs

	JSR	DrawLevelNumber
	JSR	DrawStatistics
	JSR	DrawHiScore
	JSR	DrawNLines
	JSR	DrawScore

	STZ	updateBufferOnZero

	.assert * = VBlank, lderror, "Bad flow"


.A8
.I16
ROUTINE VBlank
	LDA	mode7Hofs
	STA	M7HOFS
	LDA	mode7Hofs + 1
	STA	M7HOFS

	LDA	mode7Vofs
	STA	M7VOFS
	LDA	mode7Vofs + 1
	STA	M7VOFS


	LDA	updateOamBufferOnZero
	IF_ZERO
		TransferToOamLocation oamBuffer, 0
		STA	updateOamBufferOnZero
	ENDIF

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
ROUTINE MoveGameField
	; mode7Hofs = FPTetromones__xPos * 8 + SCREEN_TOP_HOFS
	; mode7Vofs = FPTetromones__yPos * 8 + SCREEN_TOP_VOFS

	REP	#$30
.A16
	LDA	FPTetromones__xPos
	AND	#$00FF
	ASL
	ASL
	ASL
	ADD	#SCREEN_TOP_HOFS
	STA	mode7Hofs

	LDA	FPTetromones__yPos
	AND	#$00FF
	ASL
	ASL
	ASL
	ADD	#SCREEN_TOP_VOFS
	STA	mode7Vofs

	SEP	#$20
.A8
	RTS



.A8
.I16
ROUTINE CheckPieceCollision
	; y = (DRAW_PIECE_COLUMN + FPTetromones__yPos) * SCREEN_TILE_WIDTH + FPTetromones__xPos
	; _CheckPieceCollision(y);

	.assert SCREEN_TILE_WIDTH = 32, error, "Bad value"
	REP	#$20
.A16
	LDA	FPTetromones__yPos
	AND	#$00FF
	ADD	#DRAW_PIECE_COLUMN
	ASL
	ASL
	ASL
	ASL
	ASL
	STA	drawPieceTemp

	LDA	FPTetromones__xPos
	AND	#$00FF
	ADD	drawPieceTemp
	TAY

	BRA	_CheckPieceCollision



.A8
.I16
ROUTINE CheckPieceLeftCollision
	; y = (DRAW_PIECE_COLUMN + FPTetromones__yPos) * SCREEN_TILE_WIDTH + FPTetromones__xPos - 1
	; _CheckPieceCollision(y);

	.assert SCREEN_TILE_WIDTH = 32, error, "Bad value"
	REP	#$20
.A16
	LDA	FPTetromones__yPos
	AND	#$00FF
	ADD	#DRAW_PIECE_COLUMN
	ASL
	ASL
	ASL
	ASL
	ASL
	STA	drawPieceTemp

	LDA	FPTetromones__xPos
	AND	#$00FF
	ADD	drawPieceTemp
	DEC
	TAY

	BRA	_CheckPieceCollision




.A8
.I16
ROUTINE CheckPieceRightCollision
	; y = (DRAW_PIECE_COLUMN + FPTetromones__yPos) * SCREEN_TILE_WIDTH + FPTetromones__xPos + 1
	; _CheckPieceCollision(y);

	.assert SCREEN_TILE_WIDTH = 32, error, "Bad value"
	REP	#$20
.A16
	LDA	FPTetromones__yPos
	AND	#$00FF
	ADD	#DRAW_PIECE_COLUMN
	ASL
	ASL
	ASL
	ASL
	ASL
	STA	drawPieceTemp

	LDA	FPTetromones__xPos
	AND	#$00FF
	SEC			; + 1
	ADC	drawPieceTemp
	TAY

	BRA	_CheckPieceCollision




.A8
.I16
ROUTINE CheckPieceDropCollision
	; y = (DRAW_PIECE_COLUMN + FPTetromones__yPos + 1) * SCREEN_TILE_WIDTH + FPTetromones__xPos

	.assert SCREEN_TILE_WIDTH = 32, error, "Bad value"
	REP	#$20
.A16
	LDA	FPTetromones__yPos
	AND	#$00FF
	ADD	#DRAW_PIECE_COLUMN + 1
	ASL
	ASL
	ASL
	ASL
	ASL
	STA	drawPieceTemp

	LDA	FPTetromones__xPos
	AND	#$00FF
	ADD	drawPieceTemp
	TAY

	.assert * = _CheckPieceCollision, lderror, "Bad Flow"



;; Checks collision against a given tilemap location
;; INPUT: y = tilemap index
.I16
ROUTINE _CheckPieceCollision
	; nextPiece = FPTetromones__currentPiece
	; x = 0
	;
	; for drawPieceRow = PIECE_HEIGHT to 0
	;	for drawPieceColumn = PIECE_WIDTH to 0
	;		if nextPiece->cells[x] != ' '
	;			if screenBuffer[y] != 0
	;				return true
	;		x++
	;		y++
	;
	;	y += SCREEN_TILE_WIDTH - PIECE_WIDTH
	;
	; return false

	SEP	#$20
.A8

	LDX	FPTetromones__currentPiece

	LDA	#PIECE_HEIGHT
	STA	drawPieceRow

	REPEAT
		LDA	#PIECE_WIDTH
		STA	drawPieceColumn

		REPEAT
			LDA	a:Piece::cells, X
			CMP	#' '
			IF_NE
				LDA	screenBuffer, Y
				IF_NOT_ZERO
					SEC
					RTS
				ENDIF
			ENDIF

			INX
			INY

			DEC	drawPieceColumn
		UNTIL_ZERO

		REP	#$31	; include carry
.A16
		TYA
		ADC	#SCREEN_TILE_WIDTH - PIECE_WIDTH
		TAY

		SEP	#$20
.A8
		DEC	drawPieceRow
	UNTIL_ZERO

	CLC
	RTS



; INPUT: A = line number to remove
.A8
.I16
ROUTINE HighlightLine
	; x = (DRAW_PIECE_COLUMN + line) * SCREEN_TILE_WIDTH
	; for y = 0 to N_ROWS
	;	screenBuffer[x + PLAYFIELD_ROW] = HIGHLIGHTED_TILE

	.assert SCREEN_TILE_WIDTH = 32, error, "Bad value"
	REP	#$20
.A16
	AND	#$00FF
	ADD	#DRAW_PIECE_COLUMN
	ASL
	ASL
	ASL
	ASL
	ASL
	TAX

	LDA	#HIGHLIGHTED_TILE | (HIGHLIGHTED_TILE <<8)
	.repeat	N_ROWS / 2, i
		STA	screenBuffer + i * 2 + PLAYFIELD_ROW, X
	.endrepeat

	SEP	#$20
.A8

	STZ	updateBufferOnZero

	RTS



; INPUT: A = line number to remove
.A8
.I16
ROUTINE RemoveLine
	; x = (DRAW_PIECE_COLUMN + line) * SCREEN_TILE_WIDTH
	; repeat
	;	memcpy(screenBuffer[x - SCREEN_TILE_WIDTH + PLAYFIELD_ROW], screenBuffer[x + PLAYFIELD_ROW], N_ROWS)
	;	x -= SCREEN_TILE_WIDTH
	; UNTIL x < (DRAW_PIECE_COLUMN + 1) * SCREEN_TILE_WIDTH

	.assert SCREEN_TILE_WIDTH = 32, error, "Bad value"
	REP	#$20
.A16
	AND	#$00FF
	ADD	#DRAW_PIECE_COLUMN
	ASL
	ASL
	ASL
	ASL
	ASL

	REPEAT
		TAX

		.repeat	N_ROWS / 2, i
			LDA	screenBuffer - SCREEN_TILE_WIDTH + i * 2 + PLAYFIELD_ROW, X
			STA	screenBuffer + i * 2 + PLAYFIELD_ROW, X
		.endrepeat

		TXA
		SUB	#SCREEN_TILE_WIDTH
		CMP	#(DRAW_PIECE_COLUMN + 1) * SCREEN_TILE_WIDTH
	UNTIL_LT

	SEP	#$20
.A8

	STZ	updateBufferOnZero

	RTS



.A8
.I16
ROUTINE HideCurrentPiece
	; for i = 0 to 4
	;	oamBuffer[i]::yPos = -16
	;
	; updateOamBufferOnZero = 0

	LDA	#.lobyte(-16)
	.repeat 4, i
		STA	oamBuffer + OamFormat::yPos + i * 4
	.endrepeat

	STZ	updateOamBufferOnZero

	RTS



.A8
.I16
ROUTINE DrawCurrentPiece
	; currentPiece = FPTetromones__currentPiece
	; drawPieceTile = (currentPiece->tileColor - 1) << OAM_ATTR_PALETTE_SHIFT | (3 << OAM_ATTR_ORDER_SHIFT)
	; x = 0
	;
	; for drawPieceRow = 0 to PIECE_HEIGHT
	;	for drawPieceColumn = 0 to PIECE_WIDTH
	;		if currentPiece->cells[x] != ' '
	;			oamBuffer[y]::xPos = drawPieceColumn * 8 + CURRENT_PIECE_XPOS
	;			oamBuffer[y]::yPos = drawPieceRow * 8 + CURRENT_PIECE_YPOS
	;			oamBuffer[y]::char = 0
	;			oamBuffer[y]::attr = drawPieceTile
	;
	;			y++ // actually 4 bytes
	;		x++
	;
	; updateOamBufferOnZero = 0

	LDX	FPTetromones__currentPiece

	LDA	a:Piece::tileColor, X
	DEC
	ASL
	ORA	#3 << OAM_ATTR_ORDER_SHIFT
	STA	drawPieceTile

	LDY	#0

	STZ	drawPieceRow
	REPEAT
		STZ	drawPieceColumn

		REPEAT
			LDA	a:Piece::cells, X
			CMP	#' '
			IF_NE
				LDA	drawPieceColumn
				ASL
				ASL
				ASL
				ADD	#CURRENT_PIECE_XPOS
				STA	oamBuffer + OamFormat::xPos, Y
				LDA	drawPieceRow
				ASL
				ASL
				ASL
				ADD	#CURRENT_PIECE_YPOS
				STA	oamBuffer + OamFormat::yPos, Y
				LDA	#0
				STA	oamBuffer + OamFormat::char, Y
				LDA	drawPieceTile
				STA	oamBuffer + OamFormat::attr, Y

				INY
				INY
				INY
				INY
			ENDIF

			INX

			INC	drawPieceColumn
			LDA	drawPieceColumn
			CMP	#PIECE_WIDTH
		UNTIL_GE

		INC	drawPieceRow
		LDA	drawPieceRow
		CMP	#PIECE_HEIGHT
	UNTIL_GE

	STZ	updateOamBufferOnZero

	RTS



.A8
.I16
ROUTINE DrawCurrentPieceOnField
	; nextPiece = FPTetromones__currentPiece
	; drawPieceTile = nextPiece->tileColor
	; x = 0
	; y = (DRAW_PIECE_COLUMN + FPTetromones__yPos) * SCREEN_TILE_WIDTH + FPTetromones__xPos
	;
	; for drawPieceRow = PIECE_HEIGHT to 0
	;	for drawPieceColumn = PIECE_WIDTH to 0
	;		if nextPiece->cells[x] != ' '
	;			screenBuffer[y] = drawPieceTile
	;		x++
	;		y++
	;
	;	y += SCREEN_TILE_WIDTH - PIECE_WIDTH
	; until y >= (DRAW_NEXT_COLUMN + PIECE_HEIGHT) * SCREEN_TILE_WIDTH + DRAW_NEXT_ROW
	;
	; updateOamBufferOnZero = 0

	LDX	FPTetromones__currentPiece

	LDA	a:Piece::tileColor, X
	STA	drawPieceTile

	.assert SCREEN_TILE_WIDTH = 32, error, "Bad value"
	REP	#$20
.A16
	LDA	FPTetromones__yPos
	AND	#$00FF
	ADD	#DRAW_PIECE_COLUMN
	ASL
	ASL
	ASL
	ASL
	ASL
	STA	drawPieceTemp

	LDA	FPTetromones__xPos
	AND	#$00FF
	ADD	drawPieceTemp
	TAY

	SEP	#$20
.A8

	LDA	#PIECE_HEIGHT
	STA	drawPieceRow

	REPEAT
		LDA	#PIECE_WIDTH
		STA	drawPieceColumn

		REPEAT
			LDA	a:Piece::cells, X
			CMP	#' '
			IF_NE
				LDA	drawPieceTile
				STA	screenBuffer, Y
			ENDIF

			INX
			INY

			DEC	drawPieceColumn
		UNTIL_ZERO

		REP	#$31	; include carry
.A16
		TYA
		ADC	#SCREEN_TILE_WIDTH - PIECE_WIDTH
		TAY

		SEP	#$20
.A8
		DEC	drawPieceRow
	UNTIL_ZERO

	STZ	updateBufferOnZero
	RTS


.A8
.I16
ROUTINE DrawNextPiece
	; nextPiece = FPTetromones__nextPiece
	; drawPieceTile = nextPiece->tileColor
	; x = 0
	; y = DRAW_NEXT_COLUMN * SCREEN_TILE_WIDTH + DRAW_NEXT_ROW
	;
	; repeat
	;	for drawPieceColumn = PIECE_WIDTH to 0
	;		if nextPiece->cells[x] == ' '
	;			screenBuffer[y] = 0
	;		else
	;			screenBuffer[y] = drawPieceTile
	;		x++
	;		y++
	;
	;	y += SCREEN_TILE_WIDTH - PIECE_WIDTH
	; until y >= (DRAW_NEXT_COLUMN + PIECE_HEIGHT) * SCREEN_TILE_WIDTH + DRAW_NEXT_ROW
	;
	; updateOamBufferOnZero = 0

	LDX	FPTetromones__nextPiece

	LDA	a:Piece::tileColor, X
	STA	drawPieceTile

	LDY	#DRAW_NEXT_COLUMN * SCREEN_TILE_WIDTH + DRAW_NEXT_ROW

	REPEAT
		LDA	#PIECE_WIDTH
		STA	drawPieceColumn

		REPEAT
			LDA	a:Piece::cells, X
			CMP	#' '
			IF_EQ
				LDA	#0
			ELSE
				LDA	drawPieceTile
			ENDIF

			STA	screenBuffer, Y

			INX
			INY

			DEC	drawPieceColumn
		UNTIL_ZERO

		REP	#$31	; include carry
.A16
		TYA
		ADC	#SCREEN_TILE_WIDTH - PIECE_WIDTH
		TAY

		SEP	#$20
.A8
		CPY	#(DRAW_NEXT_COLUMN + PIECE_HEIGHT) * SCREEN_TILE_WIDTH + DRAW_NEXT_ROW
	UNTIL_GE

	STZ	updateBufferOnZero

	RTS



.A8
.I16
ROUTINE DrawNLines
	; y = FPTetromones__nLines
	; tmp = DRAW_LEVEL_COLUMN * SCREEN_TILE_WIDTH + DRAW_LEVEL_ROW
	; for i = 0 to 4
	; 	y, x = y / 10, y % 10
	;	screenBuffer[tmp - i] = y + NUMBER_DIGIT_DELTA
	;	screenBuffer[tmp + 32 - i] = y + NUMBER_DIGIT_DELTA + NUMBER_DIGIT_SECOND_HALF_DELTA

	LDY	FPTetromones__nLines

	.repeat 4, i
		LDA	#10
		JSR	Math__Divide_U16Y_U8A

		TXA
		LDX	drawNumberPos
		ADD	#NUMBER_DIGIT_DELTA
		STA	screenBuffer + DRAW_NLINES_COLUMN * SCREEN_TILE_WIDTH + DRAW_NLINES_ROW - i

		ADD	#NUMBER_DIGIT_SECOND_HALF_DELTA	
		STA	screenBuffer + DRAW_NLINES_COLUMN * SCREEN_TILE_WIDTH + 32 + DRAW_NLINES_ROW - i
	.endrepeat

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

	; Clear OAM, except for the the first 4 Objects of OAM High Table.
	JSR	Reset__ClearOAM
	LDX	#128 * 4 / 2
	STX	OAMADD
	STZ	OAMDATA

	TransferToVramLocation		gameObjectsTiles, GAME_OAM_TILES
	.repeat 5, i
		TransferToCgramLocation		gameFieldPalette + 2 + 5 * 2 * i, 129 + 16 * i, 5 * 2
	.endrepeat

	ClearVramLocation		0, MODE7_TILE_WIDTH * MODE7_TILE_HEIGHT * 2
	TransferToVramLocationDataHigh	gameFieldTiles, 0
	TransferToCgramLocation		gameFieldPalette, 0, 256

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


	LDA	#TM_BG1 | TM_OBJ
	STA	TM

	RTS


.rodata
LABEL UiInitialBuffer
	.repeat	SCREEN_TILE_HEIGHT, h
		.incbin "resources/game-field.mp7", (SCREEN_UI_ROW + h) * MODE7_TILE_WIDTH + SCREEN_UI_COLUMN, SCREEN_TILE_WIDTH
	.endrepeat
UiInitialBuffer_End:


ENDMODULE

