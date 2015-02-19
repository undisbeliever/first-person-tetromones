; First Person Tetromones

.include "routines/block.h"
.include "routines/screen.h"

.include "fptetromones.h"
.include "pieces.h"
.include "ui.h"

MODULE FPTetromones

.segment "SHADOW"
	UINT32  hiScore

GameVariables:

	UINT8	level
	UINT32	score
	UINT16  lines
	UINT16	statistics, N_PIECES

	BYTE	cellsPerLine, N_LINES

	ADDR	nextPiece
	ADDR	currentPiece

	BYTE	xPos
	BYTE	yPos

GameVariables_End:


.code

.A8
.I16
ROUTINE Init
	LDXY	#DEFAULT_HI_SCORE
	STXY	hiScore



.A8
.I16
ROUTINE	PlayGame
	MemClear GameVariables

	LDA	#1
	STA	level

	;; ::DEBUG::
	LDX	Pieces__Table + 7*2
	STX	nextPiece

	JSR	Ui__Init
	JSR	Ui__DrawNextPiece
	JSR	Ui__DrawCurrentPiece
	JSR	DetermineNextPiece
	JSR	Ui__MoveGameField

	JSR	Screen__FadeIn

	REPEAT
		INC16	score

		JSR	Ui__DrawScore
		WAI
	FOREVER


.A8
.I16
ROUTINE DetermineNextPiece
	LDX	nextPiece
	STX	currentPiece

	LDA	#STARTING_XPOS
	STA	xPos
	STZ	yPos

	JSR	Ui__DrawCurrentPiece

	; ::TODO select random next piece::
	JMP	Ui__DrawNextPiece

ENDMODULE


