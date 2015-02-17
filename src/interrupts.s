; Inturrupt Handlers

.include "routines/block.h"
.include "routines/screen.h"

.include "fptetromones.h"
.include "ui.h"


;; Blank Handlers
ROUTINE IrqHandler
	RTI

ROUTINE CopHandler
	RTI

ROUTINE VBlank
	; Save state
	REP #$30
	PHA
	PHB
	PHD
	PHX
	PHY

	SEP #$20
.A8
.I16

	Screen_VBlank

	JSR	Ui__VBlank

	; Load State
	REP	#$30
	PLY
	PLX
	PLD
	PLB
	PLA
	
	RTI

