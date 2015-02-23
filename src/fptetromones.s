; First Person Tetromones

.include "routines/block.h"
.include "routines/screen.h"

.include "fptetromones.h"
.include "controls.h"
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

	;; Number of cells filled per line
	BYTE	cellsPerLine, N_LINES + 4
	;; Number of lines formed in this *turn*
	BYTE	nCompletedLines

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
	LDX	Pieces__Table + 1*2
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
	;	WaitFrame()
	;
	;	if Controls__held & JOYH_DOWN
	;		dropDelay -= FAST_DROP_SPEED
	;	else
	;		dropDelay--;
	;
	;	if dropDelay < 0
	;		c = Ui__CheckPieceDropCollision()
	;		if c set
	;			PlacePiece()
	;		else
	;			yPos += 1
	;			dropDelay = LEVEL_1_DROP_DELAY
	;			Ui__MoveGameField()
	;
	;	if Controls__pressed & JOYH_LEFT
	;		if Ui__CheckPieceLeftCollision() != true
	;			xPos--;
	;			Ui__MoveGameField()
	;			PlaySound(SOUND_MOVE_LEFT)
	;	else if Controls__pressed & JOYH_RIGHT
	;		if Ui__CheckPieceRightCollision() != true
	;			xPos++;
	;			Ui__MoveGameField()
	;			PlaySound(SOUND_MOVE_RIGHT)
	;
	REPEAT
		JSR	WaitFrame

		LDA	Controls__held + 1
		IF_BIT	#JOYH_DOWN
			LDA	dropDelay
			SUB	#FAST_DROP_SPEED
			STA	dropDelay
		ELSE
			DEC	dropDelay
		ENDIF

		IF_MINUS
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

		LDA	Controls__pressed + 1
		IF_BIT	#JOYH_LEFT
			JSR	Ui__CheckPieceLeftCollision
			IF_C_CLEAR
				DEC	xPos
				JSR	Ui__MoveGameField
				; ::SOUND move left::
			ENDIF
		ELSE_BIT	#JOYH_RIGHT
			JSR	Ui__CheckPieceRightCollision
			IF_C_CLEAR
				INC	xPos
				JSR	Ui__MoveGameField
				; ::SOUND move right::
			ENDIF
		ENDIF
	FOREVER



;; Places the current piece on the game field
.A8
.I16
ROUTINE PlacePiece
	JSR	Ui__DrawCurrentPieceOnField

	;; ::TODO increment score::

	JSR	AddToLineCounter

	LDA	nCompletedLines
	IF_NOT_ZERO
		;; ::TODO increment score::
		;; ::SOUND COMPLETED_LINE::

		JSR	RemoveCompletedLinesAnimation
	ENDIF	

	;; ::TODO check line counter::
	;; ::SOUND SOUND_DROP::

	JSR	DetermineNextPiece

	;; ::SHOULDDO slowly move screen::
	JSR	Ui__MoveGameField

	RTS


;; Increments the `cellsPerLine` variables
;; OUTPUT: nCompletedLines = number of lines that are completed.
.A8
.I16
ROUTINE AddToLineCounter
	; x = currentPiece
	; y = yPos
	; nCompletedLines = 0
	; for i = 0 to 4
	;	cellsPerLine[i + y] += x->cellsPerLine[i]
	;	if cellsPerLine[i + y] >= N_ROWS
	;		nCompletedLines++

	LDX	currentPiece

	LDA	#0
	XBA
	LDA	yPos
	TAY

	STZ	nCompletedLines

	.repeat 4, i
		LDA	cellsPerLine + i, Y
		ADD	a:Piece::cellsPerLine + i, X
		STA	cellsPerLine + i, Y

		CMP	#N_ROWS
		IF_GE
			INC	nCompletedLines
		ENDIF
	.endrepeat

	RTS


;; Remove Completed Lines
.A8
.I16
ROUTINE RemoveCompletedLinesAnimation
	JSR	Ui__HideCurrentPiece
	JSR	HighlightCompletedLines

	;; ::SHOULDDO an actual remove lines animation instead of hide::

	; // Removes Completed Lines
	; for x = 0 to .sizeof(cellsPerLine)
	;	if cellsPerLine[x] >= N_ROWS
	;		Ui__RemoveLine(x)
	;		for i = 0 to LINE_REMOVE_DELAY
	;			Screen__WaitFrame()
	;
	;		for y = X to 1
	;			cellsPerLine[y] = cellsPerLine[y - 1]

	FOR_X	#0, INC, #.sizeof(cellsPerLine)
		LDA	cellsPerLine, X
		CMP	#N_ROWS
		IF_GE
			PHX
				TXA
				JSR	Ui__RemoveLine

				LDA	#LINE_REMOVE_DELAY
				STA	dropDelay

				REPEAT
					JSR	WaitFrame
					DEC	dropDelay
				UNTIL_ZERO
			PLX
			TXY

			REPEAT
				LDA	cellsPerLine - 1, Y
				STA	cellsPerLine, Y
				DEY
			UNTIL_ZERO
		ENDIF
	NEXT

	RTS



;; Highlight Completed Lines
.A8
.I16
ROUTINE HighlightCompletedLines
	; for x = 0 to .sizeof(cellsPerLine)
	;	if cellsPerLine[x] >= N_ROWS
	;		Ui__HighlightLine(x)

	FOR_X	#0, INC, #.sizeof(cellsPerLine)
		LDA	cellsPerLine, X
		CMP	#N_ROWS
		IF_GE
			PHX
				TXA
				JSR	Ui__HighlightLine
			PLX
		ENDIF
	NEXT

	RTS



;; Selects and draws the next piece.
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



;; Waits ONE frame
;; Also calls routines that are required on every frame.
.A8
.I16
ROUTINE WaitFrame
	JSR	Screen__WaitFrame
	JMP	Controls__Update



ENDMODULE


