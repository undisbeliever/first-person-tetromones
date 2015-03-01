; Inturrupt Handlers

.include "routines/block.h"
.include "routines/screen.h"
.include "routines/random.h"

.include "fptetromones.h"
.include "ui.h"
.include "controls.h"


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
	; Reset NMI Flag.
	LDA	RDNMI

	Screen_VBlank

	JSR	Ui__VBlank

	; Must be done AFTER VRAM/OAM transfers, can go over limit.
	;
	; Had to move `Console__Update` and `Random__AddJoypadEntropy`
	; into VBlank because for some reasson setting Mode 7 matrix in
	; `Ui__VBlank` caused JOY1 to stop working in snes9x 1.51 debugger.

	JSR	Controls__Update
	JSR	Random__AddJoypadEntropy

	; Load State
	REP	#$30
	PLY
	PLX
	PLD
	PLB
	PLA
	
	RTI

