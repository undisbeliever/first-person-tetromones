; First Person Tetromones

.include "routines/block.h"
.include "routines/screen.h"

.include "fptetromones.h"
.include "ui.h"

MODULE FPTetromones

.segment "SHADOW"
	UINT32  hiScore

GameVariables:

	UINT8	level
	UINT32	score
	UINT16	statistics, N_PIECES

	ADDR	nextPiece
	ADDR	currentPiece
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

	JSR	Ui__Init
	JSR	Screen__FadeIn

	;; ::DEBUG test score::
	REPEAT
		INC32	score

		JSR	Ui__DrawScore
		WAI
	FOREVER





ENDMODULE


