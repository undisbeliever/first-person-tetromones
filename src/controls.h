.ifndef ::_CONTROLS_H_
::_CONTROLS_H_ = 1

.setcpu "65816"

; Common includes
.include "includes/import_export.inc"
.include "includes/synthetic.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"

REPEAT_DELAY = 20

IMPORT_MODULE Controls
	;; New buttons pressed on current frame.
	;; The directional buttons impletement a repeat delay
	;; which causes them to be *pressed* every `REPEAT_DELAY` frames.
	WORD	pressed

	;; Buttons that have been held for more than one frame
	WORD	held

	;; The state of the prevous frame
	WORD	previousFrame

	;; The state of the current frame
	CONST	currentFrame, JOY1


	;; Updates the control variables
	;; REQUIRE: 8 bit A, 16 bit Index, AUTOJOY enabled
	ROUTINE Update

ENDMODULE

.endif ; ::_CONTROLS_H_

; vim: set ft=asm:

