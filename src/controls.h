.ifndef ::_CONTROLS_H_
::_CONTROLS_H_ = 1

.setcpu "65816"

; Common includes
.include "includes/import_export.inc"
.include "includes/synthetic.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"

REPEAT_DELAY = 20

JOY_ROTATE_CC    = JOY_L | JOY_B
JOY_ROTATE_CW    = JOY_R | JOY_Y
JOY_INSTANT_DROP = JOY_A
JOY_HOLD_PIECE   = JOY_X

.struct RotationMoveControls
	rotateCwPtr	.addr
	rotateCcPtr	.addr

	joyh_Drop	.byte
	joyh_MoveLeft	.byte
	joyh_MoveRight	.byte
.endstruct



IMPORT_MODULE Controls
	;; New buttons pressed on current frame.
	;; The directional buttons implement a repeat delay
	;; which causes them to be *pressed* every `REPEAT_DELAY` frames.
	WORD	pressed

	;; Buttons that have been held for more than one frame
	WORD	held

	;; The state of the previous frame
	WORD	previousFrame

	;; The state of the current frame
	WORD	currentFrame

	;; Updates the control variables
	;; REQUIRE: 8 bit A, 16 bit Index, AUTOJOY enabled
	ROUTINE Update

	;; Initial Controls, 0 degrees.
	LABEL	InitialRotationMoveControls

ENDMODULE

.endif ; ::_CONTROLS_H_

; vim: set ft=asm:

