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

.include "resources.h"

NTSC_FPS = 60
PAL_FPS = 50

STARTING_XPOS = 4

N_PIECES  = 7
N_ROWS	  = 10
N_LINES   = 20
DEFAULT_HI_SCORE = 10000


IMPORT_MODULE FPTetromones

	UINT8	level
	UINT32	score
	UINT32	hiScore
	UINT16	statistics, N_PIECES

	;; Number of cells filled per line
	BYTE	cellsPerLine, N_LINES

	ADDR	nextPiece
	ADDR	currentPiece

	BYTE	xPos
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

