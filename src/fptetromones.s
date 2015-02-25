; First Person Tetromones

.include "routines/block.h"
.include "routines/screen.h"
.include "routines/random.h"

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

	;; If non-zero then the game is still playing
	;; If zero, then the game is over.
	BYTE	continuePlaying

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

	RTS


.A8
.I16
ROUTINE	PlayGame
	MemClear GameVariables

	LDA	#1
	STA	level

	JSR	Ui__Init

	JSR	DetermineNextPiece
	JSR	NewPiece

	JSR	Screen__FadeIn

	LDY	JOY1
	CPY	#JOY_SELECT
	IF_EQ
		REPEAT
			;; ::DEBUG - Test Random Number generator::
			JSR	DetermineNextPiece

			LDA	#10
			STA	yPos
			JSR	Ui__MoveGameField

			JSR	WaitFrame
		FOREVER
	ENDIF

	JSR	GameLoop

	JMP	Screen__FadeOut



;; Processes the game loop
.A8
.I16
ROUTINE GameLoop
	; continuePlaying = 1
	;
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
	; until continuePlaying == false
	;

	LDA	#1
	STA	continuePlaying

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

		LDA	continuePlaying
	UNTIL_ZERO

BREAKPOINT
	RTS




;; Places the current piece on the game field
;; If that placement creates a completed line, calls `RemoveCompletedLinesAnimation`
.A8
.I16
ROUTINE PlacePiece
	; Ui__DrawCurrentPieceOnField()
	; nCompletedLines = AddToLineCounter()
	;
	; if nCompletedLines != 0
	;	// ::TODO increment score::
	;	playSound(COMPLETED_LINE_SOUND)
	;	RemoveCompletedLinesAnimation()
	; else
	;	// ::TODO increment score::
	;	playSound(DROP_PIECE_SOUND)
	;
	; NewPiece()

	JSR	Ui__DrawCurrentPieceOnField

	JSR	AddToLineCounter

	LDA	nCompletedLines
	IF_NOT_ZERO
		;; ::TODO increment score::
		;; ::SOUND COMPLETED_LINE_SOUND ::

		JSR	RemoveCompletedLinesAnimation

		;; ::TODO increment nLines::
		;; ::TODO check if nLines > linesToNextLevel::
	ELSE
		;; ::TODO increment score::
		;; ::SOUND DROP_PIECE_SOUND ::
	ENDIF	

	JMP	NewPiece



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


;; Remove Completed Lines, slowly
.A8
.I16
ROUTINE RemoveCompletedLinesAnimation
	; Ui__HideCurrentPiece()
	; HighlightCompletedLines()
	;
	; WaitManyFrames()
	;
	; // Removes Completed Lines
	; for x = 0 to .sizeof(cellsPerLine)
	;	if cellsPerLine[x] >= N_ROWS
	;		Ui__RemoveLine(x)
	;		WaitManyFrames()
	;
	;		for y = X to 1
	;			cellsPerLine[y] = cellsPerLine[y - 1]

	JSR	Ui__HideCurrentPiece
	JSR	HighlightCompletedLines

	;; ::SHOULDDO an actual remove lines animation instead of hide::
	LDA	#LINE_REMOVE_DELAY
	JSR	WaitManyFrames

	FOR_X	#0, INC, #.sizeof(cellsPerLine)
		LDA	cellsPerLine, X
		CMP	#N_ROWS
		IF_GE
			PHX
				TXA
				JSR	Ui__RemoveLine

				LDA	#LINE_REMOVE_DELAY
				JSR	WaitManyFrames
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



;; Load New Piece from nextPiece
.A8
.I16
ROUTINE NewPiece
	; currentPiece = nextPiece
	; xPos = STARTING_XPOS
	; yPos = 0
	;
	; Ui__MoveGameField()
	; Ui__DrawCurrentPiece()
	;
	; if Ui__CheckPieceCollision() == true
	;	GameOver()
	; else
	; 	dropDelay = LEVEL_1_DROP_DELAY
	; 	statistics[currentPiece->statsIndex]++
	;
	; 	Ui__DrawStatistics()
	;	DetermineNextPiece()

	LDY	nextPiece
	STY	currentPiece

	LDA	#STARTING_XPOS
	STA	xPos
	STZ	yPos

	JSR	Ui__MoveGameField
	JSR	Ui__DrawCurrentPiece

	JSR	Ui__CheckPieceCollision
	BCS	GameOver

		;; ::TODO drop delay determined by level::
		LDA	#LEVEL_1_DROP_DELAY
		STA	dropDelay

		LDY	currentPiece
		LDX	a:Piece::statsIndex, Y
		INC16	statistics, X
		JSR	Ui__DrawStatistics

	.assert * = DetermineNextPiece, lderror, "Bad Flow"



;; Selects and draws the next piece.
.A8
.I16
ROUTINE DetermineNextPiece
	; x = Random(0, Pieces__COUNT)
	; nextPiece = Pieces__Table[x]
	; Ui__DrawNextPiece()

	LDY	#Pieces__COUNT
	JSR	Random__Rnd_U16Y

	; Select Next Piece
	REP	#$20
.A16
	TYA
	ASL
	TAX

	LDA	Pieces__Table, X
	STA	nextPiece

	SEP	#$20
.A8

	JMP	Ui__DrawNextPiece



;; Called when game is over
.A8
.I16
ROUTINE GameOver
	; playSound(SOUND_GAME_OVER)
	; repeat
	;	WaitFrame()
	;	if Controls__pressed & (JOY_BUTTONS | JOY_START)
	;		continuePlaying = false
	;		return

	;; ::SOUND GAME OVER::

	REPEAT
		JSR	WaitFrame

		REP	#$20
.A16
		LDA	Controls__pressed
		IF_BIT	#JOY_BUTTONS | JOY_START
			STZ	continuePlaying
			RTS
		ENDIF

		SEP	#$20
.A8
	FOREVER



;; Waits ONE frame
;; Also calls routines that are required on every frame.
.A8
.I16
ROUTINE WaitFrame
	JSR	Screen__WaitFrame
	JSR	Controls__Update
	JMP	Random__AddJoypadEntropy


;; Waits many frames
;; INPUT: A - number of frames to wait
.A8
.I16
ROUTINE WaitManyFrames
	; for dropDelay = A to 0
	;	WaitFrame()

	STA	dropDelay
	REPEAT
		JSR	WaitFrame
		DEC	dropDelay
	UNTIL_ZERO

	RTS


ENDMODULE


