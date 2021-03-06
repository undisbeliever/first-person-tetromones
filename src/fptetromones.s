; First Person Tetromones

.include "routines/block.h"
.include "routines/screen.h"
.include "routines/random.h"
.include "routines/math.h"

.include "fptetromones.h"
.include "controls.h"
.include "pieces.h"
.include "ui.h"


MODULE FPTetromones

.segment "SHADOW"
	UINT32  hiScore
	BYTE	firstGameOnZero

GameVariables:

	UINT16	level
	UINT32	score
	UINT16  nLines
	UINT16	statistics, N_PIECES

	;; Address of the RotationMoveControls struct
	ADDR	rotationsControls

	;; Number of lines that are dropped by holding down.
	UINT16	fastDropDistance

	;; Number of lines needed to complete the level
	UINT16	linesToNextLevel

	;; Number of cells filled per line
	BYTE	cellsPerLine, N_LINES + 4
	;; Number of lines formed in this *turn*
	BYTE	nCompletedLines

	;; If non-zero then the game is still playing
	;; If zero, then the game is over.
	BYTE	continuePlaying

	;; If zero then hold piece is enabled,
	;; If non-zero then use cannot hold.
	BYTE	canHoldPieceOnZero

	;; If zero then the next spawned piece is 0
	;; This field may be set by WaitManyFramesForSpawnDelay
	BYTE	nextPieceIsHoldPieceOnZero

	ADDR	nextPiece
	ADDR	currentPiece
	ADDR	holdPiece

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

	LDY	#LINES_PER_LEVEL
	STY	linesToNextLevel

	LDA	#1
	STA	continuePlaying
	STA	nextPieceIsHoldPieceOnZero

	LDX	#.loword(Controls__InitialRotationMoveControls)
	STX	rotationsControls

	JSR	Ui__Init

	JSR	Screen__FadeIn

	JSR	WaitForButtonPress

	LDA	Controls__currentFrame + 1
	IF_BIT	#JOYH_SELECT
		JSR	DebugTests
	ENDIF

	JSR	DetermineNextPiece
	JSR	SpawnPiece

	JSR	GameLoop

	; Press start to start new game.
	REPEAT
		LDA	Controls__currentFrame + 1
		BIT	#JOYH_START
	WHILE_ZERO
		JSR	WaitFrame
	WEND

	JMP	Screen__FadeOut



;; Processes the game loop
.A8
.I16
ROUTINE GameLoop
	; repeat:
	;	WaitFrame()
	;
	;	if Controls__currentFrame & rotationsControls->joyh_Drop
	;		dropDelay -= FAST_DROP_SPEED
	;	else
	;		dropDelay--;
	;
	;	if dropDelay < 0
	;		if Controls__currentFrame * JOY_DOWN
	;			fastDropDistance++
	;		else
	;			fastDropDistance = 0
	;
	;		c = Ui__CheckPieceDropCollision()
	;		if c set
	;			PlacePiece()
	;		else
	;			yPos += 1
	;			SetDropDelay()
	;			Ui__MoveGameField()
	;
	;
	;	if Controls__pressed & rotationsControls->joyh_MoveLeft
	;		if Ui__CheckPieceLeftCollision() != true
	;			xPos--;
	;			Ui__MoveGameField()
	;			PlaySound(SOUND_MOVE_LEFT)
	;
	;	else if Controls__pressed & rotationsControls->joyh_MoveRight
	;		if Ui__CheckPieceRightCollision() != true
	;			xPos++;
	;			Ui__MoveGameField()
	;			PlaySound(SOUND_MOVE_RIGHT)
	;
	;
	;	if Controls__pressed & JOY_INSTANT_DROP
	;			InstantDrop()
	;
	;	else if Controls__pressed & JOY_HOLD
	;			HoldPiecePressed()
	;
	;	else if Controls__pressed & JOY_ROTATE_CC
	;		if Ui__CheckPieceRotateCcCollision() != true
	;			PlaySound(SOUND_ROTATE_CC)
	;			Ui__RotateCc()
	;			currentPiece = currentPiece->rotateCcPtr
	;			rotationsControls = rotationsControls->rotateCcPtr
	;
	;	else if Controls__pressed & JOY_ROTATE_CW
	;		if Ui__CheckPieceRotateCcCollision() != true
	;			PlaySound(SOUND_ROTATE_CW)
	;			Ui__RotateCw()
	;			currentPiece = currentPiece->rotateCwPtr
	;			rotationsControls = rotationsControls->rotateCwPtr
	;
	; until continuePlaying == false
	;

	REPEAT
		JSR	WaitFrame

		LDX	rotationsControls
		LDA	Controls__currentFrame + 1
		IF_BIT	a:RotationMoveControls::joyh_Drop, X
			LDA	dropDelay
			SUB	#FAST_DROP_SPEED
			STA	dropDelay
		ELSE
			DEC	dropDelay
		ENDIF

		IF_MINUS
			LDA	Controls__currentFrame + 1
			IF_BIT	#JOYH_DOWN
				INC	fastDropDistance
			ELSE
				STZ	fastDropDistance
			ENDIF

			JSR	Ui__CheckPieceDropCollision
			IF_C_SET
				JSR	PlacePiece
			ELSE
				INC	yPos

				JSR	SetDropDelay
				JSR	Ui__MoveGameField
			ENDIF
		ENDIF

		LDX	rotationsControls
		LDA	Controls__pressed + 1
		IF_BIT	a:RotationMoveControls::joyh_MoveLeft, X
			JSR	Ui__CheckPieceLeftCollision
			IF_C_CLEAR
				DEC	xPos
				JSR	Ui__MoveGameField
				; ::SOUND move left::
			ENDIF

		ELSE_BIT a:RotationMoveControls::joyh_MoveRight, X
			JSR	Ui__CheckPieceRightCollision
			IF_C_CLEAR
				INC	xPos
				JSR	Ui__MoveGameField
				; ::SOUND move right::
			ENDIF
		ENDIF

		REP	#$20
.A16
		LDA	Controls__pressed
		IF_BIT	#JOY_HOLD_PIECE
.A16
			SEP	#$20
.A8
			JSR	HoldPiecePressed
.A16
		ELSE_BIT #JOY_INSTANT_DROP
.A16
			SEP	#$20
.A8
			JSR	InstantDrop
.A16
		ELSE_BIT #JOY_ROTATE_CC
			SEP	#$20
.A8
			JSR	Ui__CheckPieceRotateCcCollision
			IF_C_CLEAR
				; ::SOUND SOUND_ROTATE_CC::
				JSR	Ui__RotateCc

				LDX	currentPiece
				LDY	a:Piece::rotateCcPtr, X
				STY	currentPiece

				LDX	rotationsControls
				LDY	a:RotationMoveControls::rotateCcPtr, X
				STY	rotationsControls
			ENDIF
.A16
		ELSE_BIT #JOY_ROTATE_CW
			SEP	#$20
.A8
			JSR	Ui__CheckPieceRotateCwCollision
			IF_C_CLEAR
				; ::SOUND SOUND_ROTATE_CW::
				JSR	Ui__RotateCw

				LDX	currentPiece
				LDY	a:Piece::rotateCwPtr, X
				STY	currentPiece

				LDX	rotationsControls
				LDY	a:RotationMoveControls::rotateCwPtr, X
				STY	rotationsControls
			ENDIF
		ENDIF

		SEP	#$20
.A8

		LDA	continuePlaying
	UNTIL_ZERO

	RTS



;; Processes the hold piece button.
.A8
.I16
ROUTINE	HoldPiecePressed
	; if canHoldPieceOnZero == 0
	;	if holdPiece == 0
	;		holdPiece = currentPiece
	;		canHoldPieceOnZero = 1
	;
	;		Ui__DrawHoldPiece()
	;		SpawnPiece()
	;	else
	;		tmp = currentPiece
	;		currentPiece = holdPiece
	;		holdPiece = tmp
	;
	;		canHoldPieceOnZero = 1
	;
	;		xPos = STARTING_XPOS
	;		yPos = STARTING_XPOS
	;
	;		Ui__DrawHoldPiece()
	;		Ui__MoveGameField()
	;		Ui__DrawCurrentPiece()

	LDA	canHoldPieceOnZero
	IF_ZERO
		LDX	holdPiece
		IF_ZERO
			LDX	currentPiece
			STX	holdPiece

			INC	canHoldPieceOnZero

			JSR	Ui__DrawHoldPiece

			JMP	SpawnPiece

		ELSE
			LDY	currentPiece
			STX	currentPiece
			STY	holdPiece

			LDA	#STARTING_XPOS
			STA	xPos

			.assert STARTING_XPOS <> 0, error, "Bad Value"
			STA	canHoldPieceOnZero

			LDA	#STARTING_YPOS
			STA	yPos

			JSR	Ui__DrawHoldPiece
			JSR	Ui__MoveGameField
			JMP	Ui__DrawCurrentPiece
		ENDIF
	ENDIF

	RTS


;; Instantly drops the piece and waits INSTANT_DROP_DELAY frames.
.A8
.I16
ROUTINE InstantDrop
	; repeat
	;	c = Ui__CheckPieceDropCollision()
	; while c clear
	;	yPos++
	;	fastDropDistance++
	;
	; Ui__MoveGameField()
	; PlacePiece()

	REPEAT
		JSR	Ui__CheckPieceDropCollision
	WHILE_C_CLEAR
		INC	yPos
		INC	fastDropDistance
	WEND

	JSR	Ui__MoveGameField

	.assert * = PlacePiece, lderror, "Bad Flow"



;; Places the current piece on the game field
;; If that placement creates a completed line, calls `RemoveCompletedLinesAnimation`
.A8
.I16
ROUTINE PlacePiece
	; canHoldPieceOnZero = 0
	;
	; Ui__HideCurrentPiece()
	; Ui__DrawCurrentPieceOnField()
	; Ui__MoveGameField()
	;
	; WaitManyFramesForSpawnDelay(PLACE_PIECE_DELAY)
	;
	; nCompletedLines = AddToLineCounter()
	;
	; if fastDropDistance > 0
	;	score += fastDropDistance - 1
	;	fastDropDistance = 0
	;
	; UpdateScore()
	;
	; if nCompletedLines != 0
	;	ProcessCompletedLines()
	; else
	;	playSound(DROP_PIECE_SOUND)
	;
	; SpawnPiece()

	STZ	canHoldPieceOnZero

	JSR	Ui__HideCurrentPiece
	JSR	Ui__DrawCurrentPieceOnField
	JSR	Ui__MoveGameField

	LDA	#PLACE_PIECE_DELAY
	JSR	WaitManyFramesForSpawnDelay

	REP	#$21	; Clear carry
.A16
	; ::BUGFIX fastDropDistance is off by one::
	LDA	fastDropDistance
	IF_NOT_ZERO
		DEC
		ADC	score
		STA	score
		LDA	#0
		ADC	score + 2
		STA	score + 2

		STZ	fastDropDistance
	ENDIF

	SEP	#$20
.A8

	JSR	UpdateScore
	JSR	AddToLineCounter

	LDA	nCompletedLines
	IF_NOT_ZERO
		JSR	ProcessCompletedLines
	ELSE
		;; ::SOUND DROP_PIECE_SOUND ::
	ENDIF

	JMP	SpawnPiece



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


;; Increase score, remove completed lines
.A8
.I16
ROUTINE ProcessCompletedLines
	; if nCompletedLines == 4
	;	playSound(SOUND_COMPLETED_TETRIS)
	; else
	;	playSound(SOUND_COMPLETED_LINE)
	;
	; nLines += nCompletedLines
	; score += level * ScorePerLinesCleared[nCompletedLines - 1]
	;
	; if nLines >= linesToNextLevel
	;	linesToNextLevel += LINES_PER_LEVEL
	;	level++
	;	Ui__DrawLevel()
	;	playSound(SOUND_NEW_LEVEL)
	;
	; Ui__DrawLines()
	; UpdateScore()
	;
	; RemoveCompletedLinesAnimation()
	; UpdatePaletteForLevel()

	LDA	nCompletedLines
	CMP	#4
	IF_EQ
		;; ::SOUND COMPLETED_TETRIS_SOUND ::
	ELSE
		;; ::SOUND COMPLETED_LINE_SOUND ::
	ENDIF

	REP	#$20
.A16
	LDA	nCompletedLines
	AND	#$00FF
	ADD	nLines
	STA	nLines

	LDA	nCompletedLines
	AND	#$00FF
	DEC
	ASL
	TAX

	SEP	#$20
.A8
	LDY	ScorePerLinesCleared, X
	LDA	level
	JSR	Math__Multiply_U16Y_U8A_U32

	REP	#$21	; Also clear carry
.A16

	TYA
	ADC	score
	STA	score
	LDA	Math__product32 + 2
	ADC	score + 2
	STA	score + 2

	LDA	nLines
	CMP	linesToNextLevel
	IF_GE
		LDA	linesToNextLevel
		ADD	#LINES_PER_LEVEL
		STA	linesToNextLevel

		SEP	#$20
.A8
		INC	level
		JSR	Ui__DrawLevelNumber
	ENDIF

	SEP	#$20
.A8
	JSR	UpdateScore
	JSR	Ui__DrawNLines

	JSR	RemoveCompletedLinesAnimation

	; Set level color after the animation, not before.
	JSR	Ui__UpdatePaletteForLevel

	RTS



;; Remove Completed Lines, slowly
.A8
.I16
ROUTINE RemoveCompletedLinesAnimation
	; HighlightCompletedLines()
	;
	; WaitManyFramesForSpawnDelay(LINE_REMOVE_DELAY)
	;
	; // Removes Completed Lines
	; for x = 0 to .sizeof(cellsPerLine)
	;	if cellsPerLine[x] >= N_ROWS
	;		Ui__RemoveLine(x)
	;		WaitManyFramesForSpawnDelay(LINE_REMOVE_DELAY)
	;
	;		for y = X to 1
	;			cellsPerLine[y] = cellsPerLine[y - 1]

	JSR	HighlightCompletedLines

	LDA	#LINE_REMOVE_DELAY
	JSR	WaitManyFramesForSpawnDelay

	FOR_X	#0, INC, #.sizeof(cellsPerLine)
		LDA	cellsPerLine, X
		CMP	#N_ROWS
		IF_GE
			PHX
				TXA
				JSR	Ui__RemoveLine

				LDA	#LINE_REMOVE_DELAY
				JSR	WaitManyFramesForSpawnDelay
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



;; Spawn a Piece from nextPiece or holdPiece depending on `nextPieceIsHoldPieceOnZero` flag.
.A8
.I16
ROUTINE SpawnPiece
	; if nextPieceIsHoldPieceOnZero == 0
	;	if holdPiece != 0
	;		currentPiece = holdPiece
	;		holdPiece = 0
	;
	;		Ui__RemoveHoldPiece()
	;	else
	;		currentPiece = nextPiece
	;		DetermineNextPiece()
	;
	;	nextPieceIsHoldPieceOnZero = 1
	;
	; else
	; 	currentPiece = nextPiece
	;	DetermineNextPiece()
	;
	; xPos = STARTING_XPOS
	; yPos = STARTING_YPOS
	;
	; Ui__MoveGameField()
	; Ui__DrawCurrentPiece()
	;
	; if Ui__CheckPieceCollision() == true
	;	GameOver()
	; else
	;	SetDropDelay()
	; 	statistics[currentPiece->statsIndex]++
	;
	; 	Ui__DrawStatistics()


	LDA	nextPieceIsHoldPieceOnZero
	IF_ZERO
		LDX	holdPiece
		IF_NOT_ZERO
			STX	currentPiece

			LDX	#0
			STX	holdPiece

			JSR	Ui__RemoveHoldPiece
		ELSE
			LDX	nextPiece
			STX	currentPiece

			JSR	DetermineNextPiece
		ENDIF

		LDA	#1
		STA	nextPieceIsHoldPieceOnZero
	ELSE
		LDX	nextPiece
		STX	currentPiece

		JSR	DetermineNextPiece
	ENDIF

	LDA	#STARTING_XPOS
	STA	xPos
	.assert STARTING_YPOS = 0, error, "Bad Value"
	STZ	yPos

	JSR	Ui__MoveGameField
	JSR	Ui__DrawCurrentPiece

	JSR	Ui__CheckPieceCollision
	BCS	GameOver
		JSR	SetDropDelay

		LDY	currentPiece
		LDX	a:Piece::statsIndex, Y
		INC16	statistics, X
		JSR	Ui__DrawStatistics

		RTS



;; Selects and draws the next piece.
.A8
.I16
ROUTINE DetermineNextPiece
	; x = Random(0, Pieces__COUNT)
	; nextPiece = Pieces__Table[x]
	; Ui__DrawNextPiece()

	.assert Pieces__COUNT < 256, lderror, "Too many pieces"

	LDA	#.lobyte(Pieces__COUNT)
	JSR	Random__Rnd_U8A

	; Select Next Piece
	REP	#$20
.A16
	AND	#$00ff
	ASL
	TAX

	LDA	Pieces__Table, X
	STA	nextPiece

	SEP	#$20
.A8

	JMP	Ui__DrawNextPiece



;; Sets the drop delay to to the level's GravityFramesPerCellTable value
.A8
.I16
ROUTINE SetDropDelay
	;	x = level
	;	if x >= GRAVITY_MAX
	;		x = GRAVITY_MAX_LEVEL - 1
	; 	dropDelay = GravityFramesPerCellTable[x]

	LDX	level
	CPX	#GRAVITY_MAX_LEVEL
	IF_GE
		LDX	#GRAVITY_MAX_LEVEL - 1
	ENDIF

	LDA	GravityFramesPerCellTable, X
	STA	dropDelay

	RTS



;; Displays the score and checks if the hi score needs updating
.A8
.I16
ROUTINE UpdateScore
	; Ui__DrawScore
	;
	; if score >= hiScore
	;	hiScore = score
	;	Ui__DrawHiScore

	JSR	Ui__DrawScore

	LDY	score + 2
	CPY	hiScore + 2
	IF_LE
		LDY	score
		CPY	hiScore
		IF_LT
			RTS
		ENDIF
	ENDIF

	LDXY	score
	STXY	hiScore
	JMP	Ui__DrawHiScore



;; Called when game is over
.A8
.I16
ROUTINE GameOver
	; playSound(SOUND_GAME_OVER)
	; WaitForButtonPress()
	; continuePlaying = false

	;; ::SOUND GAME OVER::

	STZ	continuePlaying
	RTS



;; Tests the difficult to test code.
;; 	* tests the randomizer by constantly calling it.
;;	* rotates the screen if rotation buttons are pressed
;;	* increases the level count if start or select pressed
.A8
.I16
ROUTINE DebugTests
	; xPos = SHOW_BOARD_XPOS
	; yPos = SHOW_BOARD_YPOS
	;
	; repeat
	;	DetermineNextPiece()
	;	statistics[nextPiece->statsIndex]++
	;	Ui__DrawHiScore()
	;
	;	if statsIndex[nextPiece->statsIndex] == 999
	;		WaitForButtonPress()
	;		return
	;
	;	if Controls__currentFrame & JOY_ROTATE_CC
	;		Ui__RotateCc()
	;	elseif Controls__currentFrame & JOY_ROTATE_CW
	;		Ui__RotateCw()
	;
	;	if Controls__pressed & (JOY_START | JOY_SELECT)
	;		level++
	;		Ui__DrawLevelNumber()
	;		Ui__UpdatePaletteForLevel()
	;
	;	WaitFrame()

	LDA	#SHOW_BOARD_XPOS
	STA	xPos

	LDA	#SHOW_BOARD_YPOS
	STA	yPos

	REPEAT
		JSR	DetermineNextPiece

		LDY	nextPiece
		LDX	a:Piece::statsIndex, Y
		INC16	statistics, X

		LDY	statistics, X
		CPY	#999
		IF_EQ
			JSR	Ui__DrawStatistics
			JSR	WaitForButtonPress
			RTS
		ENDIF

		JSR	Ui__DrawStatistics

		REP	#$20
.A16


		LDA	Controls__currentFrame
		IF_BIT	#JOY_ROTATE_CC
			SEP	#$20
.A8
			JSR	Ui__RotateCc
.A16
		ELSE_BIT #JOY_ROTATE_CW
			SEP	#$20
.A8
			JSR	Ui__RotateCw
.A16
		ENDIF

		SEP	#$20
.A8

		LDA	Controls__pressed + 1
		IF_BIT	#JOYH_START | JOYH_SELECT
			INC	level
			JSR	Ui__DrawLevelNumber
			JSR	Ui__UpdatePaletteForLevel
		ENDIF

		JSR	WaitFrame
	FOREVER



;; Waits until the user presses a button
.A8
.I16
ROUTINE WaitForButtonPress
	; repeat
	;	WaitFrame()
	;	if Controls__pressed & (JOY_BUTTONS | JOY_START)
	;		return

		JSR	WaitFrame

		REP	#$20
.A16
		LDA	Controls__pressed
		AND	#JOY_BUTTONS | JOY_START

		SEP	#$20
.A8
		BEQ	WaitForButtonPress
	RTS




;; Waits many frames for the spawn delay/line removal delay
;; Will set nextPieceIsHoldPieceOnZero to 0 if `JOY_HOLD_PIECE` is set.
;;
;; INPUT: A - number of frames to wait
.A8
.I16
ROUTINE WaitManyFramesForSpawnDelay
	; for dropDelay = A to 0
	;	if Controls__pressed & JOY_HOLD_PIECE
	;		nextPieceIsHoldPieceOnZero = 0
	;	WaitFrame()

	STA	dropDelay
	REPEAT
		REP	#$20
.A16
		LDA	Controls__pressed
		AND	#JOY_HOLD_PIECE
		SEP	#$20
.A8
		IF_NOT_ZERO
			STZ	nextPieceIsHoldPieceOnZero
		ENDIF

		JSR	WaitFrame

		DEC	dropDelay
	UNTIL_ZERO

	RTS


;; Wait To the end of the frame
.A8
.I16
ROUTINE WaitFrame
	JSR	Screen__WaitFrame
	JMP	Random__AddJoypadEntropy

.rodata

LABEL ScorePerLinesCleared
	.word	40
	.word	100
	.word	300
	.word	1200


LABEL GravityFramesPerCellTable
	.byte	0	; level 0
	.byte	48	; level 1
	.byte	43	; level 2
	.byte	38	; level 3
	.byte	33	; level 4
	.byte	28	; level 5
	.byte	23	; level 6
	.byte	18	; level 7
	.byte	13	; level 8
	.byte	8	; level 9
	.byte	6	; level 10
	.byte	5	; level	11
	.byte	5	; level	12
	.byte	5	; level	13
	.byte	4	; level 14
	.byte	4	; level 15
	.byte	4	; level 16
	.byte	3	; level 17
	.byte	3	; level 18
	.byte	3	; level 19
	.byte	3	; level 20

GRAVITY_MAX_LEVEL = * - GravityFramesPerCellTable


ENDMODULE

