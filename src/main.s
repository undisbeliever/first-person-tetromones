; Initialisation code

.include "fptetromones.h"
.include "routines/random.h"

;; Initialisation Routine
ROUTINE Main
	REP	#$10
	SEP	#$20
.A8
.I16

	; ::TODO Setup Sound Engine::

	LDA	#NMITIMEN_VBLANK_FLAG | NMITIMEN_AUTOJOY_FLAG
	STA	NMITIMEN

	LDXY	#$c0aa5674		; source: random.org
	STXY	Random__seed

	JSR	FPTetromones__Init

	REPEAT
		JSR	FPTetromones__PlayGame
	FOREVER


.segment "COPYRIGHT"
		;1234567890123456789012345678901
	.byte	"First Person Tetromones        ", 10
	.byte	"(c) 2015, The Undisbeliever    ", 10
	.byte	"MIT Licensed                   ", 10
	.byte	"One Game Per Month Challange   ", 10

