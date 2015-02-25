; Initialisation code

.include "fptetromones.h"
.include "includes/sfc_header.inc"



;; Initialisation Routine
ROUTINE Main
	REP	#$10
	SEP	#$20
.A8
.I16

	; ::TODO Setup Sound Engine::

	LDA	#NMITIMEN_VBLANK_FLAG | NMITIMEN_AUTOJOY_FLAG
	STA	NMITIMEN

	JSR	FPTetromones__Init

	REPEAT
		JSR	FPTetromones__PlayGame
	FOREVER

