; First Person Tetromones

.include "routines/block.h"
.include "routines/screen.h"

.include "fptetromones.h"
.include "pieces.h"
.include "ui.h"

MODULE FPTetromones

;; ::DEBUG replace with table::
LEVEL_1_DROP_DELAY = 50

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

	BYTE	dropDelay

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

	.assert * = GameLoop, lderror, "Bad Flow"



;; Processes the game loop
.A8
.I16
ROUTINE GameLoop
	; repeat:
	;	if --dropDelay == 0
	;		c = Ui__CheckPieceDropCollision()
	;		if c set
	;			PlacePiece()
	;		else
	;			yPos += 1
	;			dropDelay = LEVEL_1_DROP_DELAY
	;			Ui__MoveGameField()
	;	Screen__WaitFrame()
	REPEAT
		DEC	dropDelay
		IF_ZERO
			JSR	Ui__CheckPieceDropCollision
			IF_C_SET
				JSR	PlacePiece
			ELSE
				INC	yPos
				LDA	#LEVEL_1_DROP_DELAY
				STA	dropDelay

				JSR	Ui__MoveGameField
			ENDIF
		ENDIF

		JSR	Screen__WaitFrame
	FOREVER



;; Places the current piece on the game field
.A8
.I16
ROUTINE PlacePiece
	JSR	Ui__DrawCurrentPieceOnField

	;; ::TODO increment score::

	;; ::TODO add to line counter::
	;; ::TODO check line counter::

	JSR	DetermineNextPiece

	;; ::SHOULDDO slowly move screen::
	JSR	Ui__MoveGameField

	RTS


.A8
.I16
ROUTINE DetermineNextPiece
	LDX	nextPiece
	STX	currentPiece

	LDA	#STARTING_XPOS
	STA	xPos
	STZ	yPos

	LDA	#LEVEL_1_DROP_DELAY
	STA	dropDelay

	;; ::TODO game over check::

	JSR	Ui__DrawCurrentPiece

	; ::TODO select random next piece::
	JMP	Ui__DrawNextPiece

ENDMODULE


