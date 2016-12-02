; Handle controls, including repeating characters.

.include "controls.h"


MODULE Controls

.rodata

LABEL	InitialRotationMoveControls
RotationControls_0:
	.addr	RotationControls_270
	.addr	RotationControls_90

	.byte	JOYH_DOWN
	.byte	JOYH_LEFT
	.byte	JOYH_RIGHT


RotationControls_90:
	.addr	RotationControls_0
	.addr	RotationControls_180

	.byte	JOYH_RIGHT
	.byte	JOYH_DOWN
	.byte	JOYH_UP


RotationControls_180:
	.addr	RotationControls_90
	.addr	RotationControls_270

	.byte	JOYH_UP
	.byte	JOYH_RIGHT
	.byte	JOYH_LEFT


RotationControls_270:
	.addr	RotationControls_180
	.addr	RotationControls_0

	.byte	JOYH_LEFT
	.byte	JOYH_UP
	.byte	JOYH_DOWN




.segment "SHADOW"
	WORD	pressed
	WORD	held
	WORD	previousFrame
	WORD	currentFrame

	WORD	invertedPrevious

	;; countdown for repeat delay.
	BYTE	upCounter
	BYTE	downCounter
	BYTE	leftCounter
	BYTE	rightCounter



.code

;; inline test for each countdown.
;; INPUT: A = JOY1H
;; MODIFIES: A
;; MUST NOT MODIFY Y
;; REQUIRE: 
;;	8 bit A
;;	joyhTest must be a single button.
.macro _Update_DelayTestButton  joyhTest, counter
	; if joy1h AND joyhTest != 0
	;	if --counter == 0
	;		invertedPrevious.h = invertedPrevious | joyhTest
	;	else
	;		counter = REPEAT_DELAY
	; else
	;	counter = REPEAT_DELAY
	.local _ResetDelay
	.local _SkipResetDelay

	AND	#joyhTest
	BEQ	_ResetDelay

		DEC	counter
		BNE	_SkipResetDelay

			TSB	invertedPrevious + 1
_ResetDelay:
		LDA	#REPEAT_DELAY
		STA	counter

_SkipResetDelay:

.endmacro


.A8
.I16
ROUTINE Update
	; repeat
	; until JVJOY & HVJOY_AUTOJOY == 0
	;
	; currentFrame = JOY1
	; held = JOY1 & previousFrame
	; previousFrame = JOY1
	; pressed = JOY1 & invertedPrevious
	; invertedPrevious = JOY1 ^ 0xFFFF
	;
	; _Update_DelayTestButton(JOY1_H, JOYH_UP, upCounter)
	; _Update_DelayTestButton(JOY1_H, JOYH_DOWN, downCounter)
	; _Update_DelayTestButton(JOY1_H, JOYH_LEFT, leftCounter)
	; _Update_DelayTestButton(JOY1_H, JOYH_RIGHT, rightCounter)

	LDA	#HVJOY_AUTOJOY
_Update_loop:
		BIT	HVJOY
		BNE	_Update_loop

	REP	#$20
.A16
	LDA	JOY1
	STA	currentFrame
	AND	previousFrame
	STA	held

	LDA	JOY1
	STA	previousFrame

	AND	invertedPrevious
	STA	pressed

	LDA	JOY1
	EOR	#$FFFF
	STA	invertedPrevious

	SEP	#$20
.A8

	LDA	JOY1H
	TAY
	_Update_DelayTestButton JOYH_UP, upCounter

	TYA
	_Update_DelayTestButton JOYH_DOWN, downCounter

	TYA
	_Update_DelayTestButton JOYH_LEFT, leftCounter

	TYA
	_Update_DelayTestButton JOYH_RIGHT, rightCounter

	RTS

ENDMODULE

