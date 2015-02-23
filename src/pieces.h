.ifndef ::_PIECES_H_
::_PIECES_H_ = 1

.setcpu "65816"

; Common includes
.include "includes/import_export.inc"
.include "includes/synthetic.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"

.include "resources.h"


PIECE_WIDTH = 4
PIECE_HEIGHT = 4

.struct Piece
	;; Rotate Clockwise - Pointer to Piece
	rotateCwPtr 	.addr
	;; Rotate Counter Clockwise - Pointer to Piece
	rotateCcPtr	.addr

	;; Index of the piece in the statistics table.
	;; Piece number * 2.
	statsNumber	.word

	;; The color of the tiles (1 - 4)
	tileColor	.byte

	;; Leftmost tile position 
	left		.byte
	;; Rightmost tile postion
	right		.byte

	;; A table of the number of cells per line.
	cellsPerLine	.res 4

	;; The location of the cells. space is clear, anything else has a tile.
	cells		.res 4 * 4
.endstruct


IMPORT_MODULE Pieces
	;; A table of addresses of the various pieces in the game.
	LABEL	Table

	;; The number of pieces in the table.
	LABEL	COUNT
ENDMODULE

.endif ; ::_PIECES_H_

; vim: set ft=asm:

