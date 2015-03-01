.ifndef ::_FPTETROMONES_H_
::_FPTETROMONES_H_ = 1

.define VERSION 1
.define REGION NTSC
.define ROM_NAME "1ST PERSON TETROMONES"

.setcpu "65816"

; Common includes
.include "includes/import_export.inc"
.include "includes/synthetic.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"
.include "routines/metasprite.h"

.include "resources.h"

NTSC_FPS = 60
PAL_FPS = 50

STARTING_XPOS = 5
STARTING_YPOS = 0

SHOW_BOARD_XPOS = 6
SHOW_BOARD_YPOS = 11

;; Number of frames to wait when dropping a line
LINE_REMOVE_DELAY = 12

N_PIECES  = 7
N_ROWS	  = 10
N_LINES   = 20
DEFAULT_HI_SCORE = 10000

FAST_DROP_SPEED = 20


IMPORT_MODULE FPTetromones

	UINT32	hiScore

	UINT8	level
	UINT32	score
	UINT16  nLines
	UINT16	statistics, N_PIECES

	ADDR	nextPiece
	ADDR	currentPiece

	;; X Position of current piece relative to screenBuffer left in tiles
	BYTE	xPos
	;; Y Position of current piece relative to top of theplayable area in tiles.
	BYTE	yPos


	;; Initializes the game, initial hi-score
	;;
	;; REQUIRES: 8 bit A, 16 bit Index
	ROUTINE	Init

	;; Plays a nice, friendly game of First Person Tetromones
	;;
	;; REQUIRES: 8 bit A, 16 bit Index
	ROUTINE	PlayGame

ENDMODULE


.endif ; ::_FPTETROMONES_H_

; vim: set ft=asm:

