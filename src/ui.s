
.include "includes/registers.inc"
.include "routines/metasprite.h"
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

	WORD	paletteBuffer, 256
	BYTE	updatePaletteOnZero

	UINT16	mode7xPos
	UINT16	mode7yPos
	UINT16	mode7hofs
	UINT16	mode7vofs
	ADDR	mode7MatrixPtr

	;; Index within RotationTable for current rotation alignment
	ADDR	rotationIndex

	BYTE	screenBuffer, SCREEN_TILE_WIDTH * SCREEN_TILE_HEIGHT
	BYTE	updateBufferOnZero

	WORD	drawNumberPos
	BYTE	drawPieceRow
	BYTE	drawPieceColumn
	WORD	drawPieceTemp
	BYTE	drawPieceXOffset
	BYTE	drawPieceYOffset


	SAME_VARIABLE	drawPieceTile, drawNumberPos

.code

.A8
.I16
ROUTINE Init
	MemCopy UiInitialBuffer, screenBuffer

	JSR	SetupScreen

	LDY	#PIECE_XPOS + 8 * SHOW_BOARD_XPOS
	STY	mode7xPos
	LDY	#PIECE_YPOS + 8 * SHOW_BOARD_YPOS
	STY	mode7yPos

	LDY	#PIECE_XPOS - PIECE_000_HOFFSET + 8 * SHOW_BOARD_XPOS
	STY	mode7hofs
	LDY	#PIECE_YPOS - PIECE_000_VOFFSET + 8 * SHOW_BOARD_YPOS
	STY	mode7vofs

	LDX	#0
	STX	rotationIndex

	LDX	#.loword(RotateTable_0)
	STX	mode7MatrixPtr

	JSR	Ui__HideCurrentPiece
	JSR	DrawLevelNumber
	JSR	DrawStatistics
	JSR	DrawHiScore
	JSR	DrawNLines
	JSR	DrawScore
	JSR	UpdatePaletteForLevel

	STZ	updateBufferOnZero

	.assert * = VBlank, lderror, "Bad flow"


.A8
.I16
ROUTINE VBlank
	LDA	mode7xPos
	STA	M7X
	LDA	mode7xPos + 1
	STA	M7X

	LDA	mode7yPos
	STA	M7Y
	LDA	mode7yPos + 1
	STA	M7Y

	LDA	mode7hofs
	STA	M7HOFS
	LDA	mode7hofs + 1
	STA	M7HOFS

	LDA	mode7vofs
	STA	M7VOFS
	LDA	mode7vofs + 1
	STA	M7VOFS

	; store mode 7 registers from RotateTable data
	LDX	mode7MatrixPtr
	.repeat	4, i
		; low
		LDA	a:i * 2 + 0, X
		STA	M7A + i
		; high
		LDA	a:i * 2 + 1, X
		STA	M7A + i
	.endrepeat

	LDA	updatePaletteOnZero
	IF_ZERO
		TransferToCgramLocation paletteBuffer, 0
		STA	updatePaletteOnZero
	ENDIF

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
	; x = FPTetromones__currentPiece
	; mode7xPos = FPTetromones__xPos * 8 + PIECE_XPOS + x->xOffset
	; mode7yPos = FPTetromones__yPos * 8 + PIECE_YPOS + x->yOffset
	;
	; if x == Pieces__Square
	;	mode7xPos += SquarePieceXOffset[rotationIndex]
	;	mode7yPos += SquarePieceYOffset[rotationIndex]
	;
	; mode7hofs = mode7xPos - HOffsetTable[rotationIndex]
	; mode7vofs = mode7yPos - VOffsetTable[rotationIndex]

	REP	#$20
.A16

	LDX	FPTetromones__currentPiece

	LDA	FPTetromones__xPos
	AND	#$00FF
	ASL
	ASL
	ASL
	ADD	#PIECE_XPOS
	ADD	a:Piece::xOffset, X
	STA	mode7xPos

	LDA	FPTetromones__yPos
	AND	#$00FF
	ASL
	ASL
	ASL
	ADD	#PIECE_YPOS
	ADD	a:Piece::yOffset, X
	STA	mode7yPos

	; ::HACK fix the square position::
	; Could not find a proper way to solve the positioning
	; problem of the square piece.

	CPX	#.loword(Pieces__Square)
	IF_EQ
		LDX	rotationIndex

		LDA	mode7xPos
		ADD	Pieces__SquarePieceXOffset, X
		STA	mode7xPos

		LDA	mode7yPos
		ADD	Pieces__SquarePieceYOffset, X
		STA	mode7yPos
	ENDIF

	LDX	rotationIndex

	LDA	mode7xPos
	SUB	HOffsetTable, X
	STA	mode7hofs

	LDA	mode7yPos
	SUB	VOffsetTable, X
	STA	mode7vofs

	SEP	#$20
.A8
	RTS



.A8
.I16
ROUTINE RotateCc
	; mode7MatrixPtr = RotationTable[rotationIndex]
	;
	; for drawPieceTemp = N_ROTATION_FRAMES - 1 to 0
	;	Screen__WaitFrame()
	;	mode7MatrixPtr += 1 // actually 4 words = 8
	;
	; rotationIndex = (rotationIndex + 2) % (4 * 2)
	;
	; MoveGameField()

	REP	#$20
.A16
	LDX	rotationIndex
	LDA	RotationTable, X
	STA	mode7MatrixPtr

	LDA	#N_ROTATION_FRAMES - 1
	STA	drawPieceTemp
	REPEAT
		JSR	Screen__WaitFrame

		LDA	mode7MatrixPtr
		ADD	#4 * 2
		STA	mode7MatrixPtr

		DEC	drawPieceTemp
	UNTIL_ZERO

	LDA	rotationIndex
	INC
	INC
	AND	#$07
	STA	rotationIndex

	JMP	MoveGameField



.A8
.I16
ROUTINE RotateCw
	; rotationIndex = (rotationIndex - 2) % (4 * 2)
	; mode7MatrixPtr = RotationTable[rotationIndex] + (N_ROTATION_FRAMES - 1) * 8 //for 4 words
	;
	; for drawPieceTemp = N_ROTATION_FRAMES - 1 to 0
	;	Screen__WaitFrame()
	;	mode7MatrixPtr -= 1 // actually 4 words = 8
	;
	; MoveGameField()

	REP	#$20
.A16

	LDA	rotationIndex
	DEC
	DEC
	AND	#$07
	STA	rotationIndex

	TAX
	LDA	RotationTable, X
	ADC	#(N_ROTATION_FRAMES - 1) * 4 * 2
	STA	mode7MatrixPtr

	LDA	#N_ROTATION_FRAMES - 1
	STA	drawPieceTemp
	REPEAT
		JSR	Screen__WaitFrame

		LDA	mode7MatrixPtr
		SUB	#4 * 2
		STA	mode7MatrixPtr

		DEC	drawPieceTemp
	UNTIL_ZERO

	JMP	MoveGameField


.A8
.I16
ROUTINE CheckPieceRotateCwCollision
	; _CheckPieceCollision_CurrentPosition(FPTetromones__currentPiece->rotateCwPtr)

	LDY	FPTetromones__currentPiece
	LDX	a:Piece::rotateCwPtr, Y

	BRA	_CheckPieceCollision_CurrentPosition


.A8
.I16
ROUTINE CheckPieceRotateCcCollision
	; _CheckPieceCollision_CurrentPosition(FPTetromones__currentPiece->rotateCcPtr)

	LDY	FPTetromones__currentPiece
	LDX	a:Piece::rotateCcPtr, Y

	BRA	_CheckPieceCollision_CurrentPosition


.A8
.I16
ROUTINE CheckPieceCollision
	; _CheckPieceCollision_CurrentPosition(FPTetromones__currentPiece)

	LDX	FPTetromones__currentPiece

	.assert * = _CheckPieceCollision_CurrentPosition, lderror, "Bad Flow"


;; INPUT: x = piece to test
.A8
.I16
ROUTINE _CheckPieceCollision_CurrentPosition
	; y = (DRAW_PIECE_COLUMN + FPTetromones__yPos) * SCREEN_TILE_WIDTH + DRAW_PIECE_ROW + FPTetromones__xPos
	; _CheckPieceCollision(y, x);

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
	ADD	#DRAW_PIECE_ROW
	ADD	drawPieceTemp
	TAY

	BRA	_CheckPieceCollision


.A8
.I16
ROUTINE CheckPieceLeftCollision
	; y = (DRAW_PIECE_COLUMN + FPTetromones__yPos) * SCREEN_TILE_WIDTH + FPTetromones__xPos + DRAW_PIECE_ROW - 1
	; _CheckPieceCollision(y, FPTetromones__currentPiece);

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
	ADD	#DRAW_PIECE_ROW
	DEC
	TAY

	LDX	FPTetromones__currentPiece

	BRA	_CheckPieceCollision




.A8
.I16
ROUTINE CheckPieceRightCollision
	; y = (DRAW_PIECE_COLUMN + FPTetromones__yPos) * SCREEN_TILE_WIDTH + FPTetromones__xPos + DRAW_PIECE_ROW + 1
	; _CheckPieceCollision(y, FPTetromones__currentPiece);

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
	ADD	#DRAW_PIECE_ROW
	TAY

	LDX	FPTetromones__currentPiece

	BRA	_CheckPieceCollision


.A8
.I16
ROUTINE CheckPieceDropCollision
	; y = (DRAW_PIECE_COLUMN + FPTetromones__yPos + 1) * SCREEN_TILE_WIDTH + FPTetromones__xPos + DRAW_PIECE_ROW
	; _CheckPieceCollision(y, FPTetromones__currentPiece);

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
	ADD	#DRAW_PIECE_ROW
	TAY

	LDX	FPTetromones__currentPiece

	.assert * = _CheckPieceCollision, lderror, "Bad Flow"



;; Checks collision against a given tilemap location
;; INPUT: y = tilemap index
;;	  x = piece to test
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
	; x = (CLEAR_LINES_COLUMN + line) * SCREEN_TILE_WIDTH
	; for y = 0 to N_ROWS
	;	screenBuffer[x + CLEAR_LINES_ROW] = HIGHLIGHTED_TILE

	.assert SCREEN_TILE_WIDTH = 32, error, "Bad value"
	REP	#$20
.A16
	AND	#$00FF
	ADD	#CLEAR_LINES_COLUMN
	ASL
	ASL
	ASL
	ASL
	ASL
	TAX

	LDA	#HIGHLIGHTED_TILE | (HIGHLIGHTED_TILE <<8)
	.repeat	N_ROWS / 2, i
		STA	screenBuffer + i * 2 + CLEAR_LINES_ROW, X
	.endrepeat

	SEP	#$20
.A8

	STZ	updateBufferOnZero

	RTS



; INPUT: A = line number to remove
.A8
.I16
ROUTINE RemoveLine
	; x = (CLEAR_LINES_COLUMN + line) * SCREEN_TILE_WIDTH
	; repeat
	;	memcpy(screenBuffer[x - SCREEN_TILE_WIDTH + CLEAR_LINES_ROW], screenBuffer[x + DRAW_PIECE_ROW], N_ROWS)
	;	x -= SCREEN_TILE_WIDTH
	; UNTIL x < (CLEAR_LINES_COLUMN + 1) * SCREEN_TILE_WIDTH

	.assert SCREEN_TILE_WIDTH = 32, error, "Bad value"
	REP	#$20
.A16
	AND	#$00FF
	ADD	#CLEAR_LINES_COLUMN
	ASL
	ASL
	ASL
	ASL
	ASL

	REPEAT
		TAX

		.repeat	N_ROWS / 2, i
			LDA	screenBuffer - SCREEN_TILE_WIDTH + i * 2 + CLEAR_LINES_ROW, X
			STA	screenBuffer + i * 2 + CLEAR_LINES_ROW, X
		.endrepeat

		TXA
		SUB	#SCREEN_TILE_WIDTH
		CMP	#(CLEAR_LINES_COLUMN + 1) * SCREEN_TILE_WIDTH
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
	; for i = 0 to rotationIndex / 2
	;	currentPiece = currentPiece->rotateCwPtr
	;
	; drawPieceTile = (currentPiece->tileColor - 1) << OAM_ATTR_PALETTE_SHIFT | (3 << OAM_ATTR_ORDER_SHIFT)
	;
	; yOffset = currentPiece->xOffset
	; yOffset = currentPiece->xOffset
	;
	; x = 0
	; y = 0
	; for drawPieceRow = 0 to PIECE_HEIGHT
	;	for drawPieceColumn = 0 to PIECE_WIDTH
	;		if currentPiece->cells[x] != ' '
	;			oamBuffer[y]::xPos = drawPieceColumn * 8 + SCREEN_WIDTH / 2 - xOffset
	;			oamBuffer[y]::yPos = drawPieceRow * 8 + SCREEN_HEIGHT / 2 - yOfffset
	;			oamBuffer[y]::char = 0
	;			oamBuffer[y]::attr = drawPieceTile
	;
	;			y++ // actually 4 bytes
	;		x++
	;
	; updateOamBufferOnZero = 0

	LDX	FPTetromones__currentPiece

	; rotate piece so it matches screen.
	LDA	rotationIndex
	LSR
	IF_NOT_ZERO
		REPEAT
			LDY	a:Piece::rotateCwPtr, X
			TYX

			DEC
		UNTIL_ZERO
	ENDIF

	LDA	a:Piece::tileColor, X
	DEC
	ASL
	ORA	#3 << OAM_ATTR_ORDER_SHIFT
	STA	drawPieceTile

	LDA	a:Piece::xOffset, X
	STA	drawPieceXOffset
	LDA	a:Piece::yOffset, X
	STA	drawPieceYOffset

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
				ADD	#SCREEN_WIDTH / 2
				SUB	drawPieceYOffset
				STA	oamBuffer + OamFormat::xPos, Y
				LDA	drawPieceRow
				ASL
				ASL
				ASL
				ADD	#SCREEN_HEIGHT / 2
				SUB	drawPieceXOffset
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
	; y = (DRAW_PIECE_COLUMN + FPTetromones__yPos) * SCREEN_TILE_WIDTH + FPTetromones__xPos + DRAW_PIECE_ROW
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
	; updateBufferOnZero = 0

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
	ADD	#DRAW_PIECE_ROW
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
ROUTINE DrawHoldPiece
	; pos = DRAW_HOLD_COLUMN * SCREEN_TILE_WIDTH + DRAW_HOLD_ROW
	; _DrawPieceTilesInBox(FPTetromones__holdPiece, pos)

	LDX	FPTetromones__holdPiece
	LDY	#DRAW_HOLD_COLUMN * SCREEN_TILE_WIDTH + DRAW_HOLD_ROW

	BRA	_DrawPieceTilesInBox



.A8
.I16
ROUTINE DrawNextPiece
	; pos = DRAW_NEXT_COLUMN * SCREEN_TILE_WIDTH + DRAW_NEXT_ROW
	; _DrawPieceTilesInBox(FPTetromones__nextPiece, pos)

	LDX	FPTetromones__nextPiece
	LDY	#DRAW_NEXT_COLUMN * SCREEN_TILE_WIDTH + DRAW_NEXT_ROW

	.assert * = _DrawPieceTilesInBox, lderror, "Bad Flow"



;; Draws the piece as a box in the screen (overriding the tiles)
;; INPUT:
;; 	X = piece
;; 	Y = tile position
.A8
.I16
ROUTINE _DrawPieceTilesInBox
	; drawPieceTile = x->tileColor
	;
	; for drawPieceRow = PIECE_HEIGHT to 0
	;	for drawPieceColumn = PIECE_WIDTH to 0
	;		if x->cells[x] == ' '
	;			screenBuffer[y] = 0
	;		else
	;			screenBuffer[y] = drawPieceTile
	;		x++
	;		y++
	;
	;	y += SCREEN_TILE_WIDTH - PIECE_WIDTH
	;
	; updateOamBufferOnZero = 0

	LDA	a:Piece::tileColor, X
	STA	drawPieceTile

	LDA	#PIECE_HEIGHT
	STA	drawPieceRow

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
		DEC	drawPieceRow
	UNTIL_ZERO

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


.A8
.I16
ROUTINE RemoveHoldPiece
	; x = DRAW_HOLD_COLUMN * SCREEN_TILE_WIDTH + DRAW_HOLD_ROW
	;
	; for drawPieceRow = PIECE_HEIGHT to 0
	;	for c = PIECE_WIDTH to 0
	;		screenBuffer[x + c] = 0
	;
	;	x += SCREEN_TILE_WIDTH
	;
	; updateBufferOnZero = 0

	LDX	#DRAW_HOLD_COLUMN * SCREEN_TILE_WIDTH + DRAW_HOLD_ROW

	REP	#$30
.A16

	LDA	#PIECE_HEIGHT
	STA	drawPieceRow

	REPEAT
		.assert PIECE_HEIGHT .mod 4 = 0, error, "Bad Value"

		.repeat	PIECE_WIDTH / 2, c
			STZ	screenBuffer + c * 2, X
		.endrepeat

		TXA
		ADD	#SCREEN_TILE_WIDTH
		TAX

		DEC	drawPieceRow
	UNTIL_ZERO

	SEP	#$20
.A8

	STZ	updateBufferOnZero

	RTS



;; Sets the palette of the screen
.A8
.I16
ROUTINE	UpdatePaletteForLevel
	; x = LevelPaletteTable[(FPTetromones__level - 1) % N_LEVEL_PALETTES]
	;
	; for tile = 0 to N_PIECE_TILES
	;	for color = 0 to N_TILE_COLORS
	;		paletteBuffer[tile * N_TILE_COLORS + color + 1] = x[tile * N_TILE_COLORS + color]
	;		paletteBuffer[128 + tile * 16 + color + 1] = x[tile * N_TILE_COLORS + color]

	LDY	FPTetromones__level
	DEY
	LDA	#N_LEVEL_PALETTES
	JSR	Math__Divide_U16Y_U8A

	REP	#$20
.A16

	TXA
	ASL
	TAY

	LDX	LevelPaletteTable, Y

	.repeat N_PIECE_TILES, tile
		.repeat N_TILE_COLORS, color
			LDA	a:2 * (tile * N_TILE_COLORS + color), X
			STA	a:paletteBuffer + (tile * N_TILE_COLORS + color + 1) * 2
			STA	a:paletteBuffer + (128 + tile * 16 + color + 1) * 2
		.endrepeat
	.endrepeat

	SEP	#$20
.A8

	STZ	updatePaletteOnZero

	RTS



;; Sets up the Screen Registers and loads tiles, maps and palette to PPU
.A8
.I16
ROUTINE SetupScreen
	LDA	#INIDISP_FORCE
	STA	INIDISP

	LDA	#GAME_MODE
	STA	BGMODE

	Screen_SetVramBaseAndSize GAME

	; Clear OAM, except for the the first 4 Objects of OAM High Table.
	JSR	Reset__ClearOAM
	LDX	#128 * 4 / 2
	STX	OAMADD
	STZ	OAMDATA

	TransferToVramLocation		gameObjectsTiles, GAME_OAM_TILES

	ClearVramLocation		0, MODE7_TILE_WIDTH * MODE7_TILE_HEIGHT * 2
	TransferToVramLocationDataHigh	gameFieldTiles, 0
	MemCopy				gameFieldPalette, paletteBuffer, 256

	STZ	updatePaletteOnZero

	LDA	#TM_BG1 | TM_OBJ
	STA	TM

	RTS


.rodata
LABEL HOffsetTable
	.word	PIECE_000_HOFFSET
	.word	PIECE_090_HOFFSET
	.word	PIECE_180_HOFFSET
	.word	PIECE_270_HOFFSET


LABEL VOffsetTable
	.word	PIECE_000_VOFFSET
	.word	PIECE_090_VOFFSET
	.word	PIECE_180_VOFFSET
	.word	PIECE_270_VOFFSET


LABEL UiInitialBuffer
	.repeat	SCREEN_TILE_HEIGHT, h
		.incbin "resources/mode7/game-field.mp7", (SCREEN_UI_ROW + h) * MODE7_TILE_WIDTH + SCREEN_UI_COLUMN, SCREEN_TILE_WIDTH
	.endrepeat
UiInitialBuffer_End:

	.include "tables/rotations.inc"

	.include "tables/level-colors.inc"

ENDMODULE

