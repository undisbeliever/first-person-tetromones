.ifndef ::_UI_H_
::_UI_H_ = 1

.setcpu "65816"

; Common includes
.include "includes/import_export.inc"
.include "includes/synthetic.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"
.include "routines/metasprite.h"

.include "resources.h"

;; Game Center
MODE7_CENTERX	= 512
MODE7_CENTERY	= 512

SCREEN_WIDTH = 256
SCREEN_HEIGHT = 224

;; The start of the screen column.
DRAW_PIECE_COLUMN  = 3
;; The start of the screen row - 2 rows are used for padding for I piece.
DRAW_PIECE_ROW     = 9

CLEAR_LINES_COLUMN  = 3
CLEAR_LINES_ROW    = 11

;; The tile that signifies a row for removal.
HIGHLIGHTED_TILE   = 5

PIECE_XPOS = MODE7_CENTERX - N_ROWS / 2 * 8 - 16
PIECE_YPOS = MODE7_CENTERY - N_LINES / 2 * 8 - 8

;; center position of the top left of the game field
PIECE_000_HOFFSET = SCREEN_WIDTH / 2
PIECE_000_VOFFSET = SCREEN_HEIGHT / 2 + 1

PIECE_090_HOFFSET = SCREEN_WIDTH / 2
PIECE_090_VOFFSET = SCREEN_HEIGHT / 2

PIECE_180_HOFFSET = SCREEN_WIDTH / 2 - 1
PIECE_180_VOFFSET = SCREEN_HEIGHT / 2

PIECE_270_HOFFSET = SCREEN_WIDTH / 2 - 1
PIECE_270_VOFFSET = SCREEN_HEIGHT / 2 + 1



MODE7_TILE_WIDTH  = 128
MODE7_TILE_HEIGHT = 128

SCREEN_UI_COLUMN = 48
SCREEN_UI_ROW    = 50

SCREEN_TILE_HEIGHT = 28
SCREEN_TILE_WIDTH  = 32

NUMBER_DIGIT_DELTA = 6
NUMBER_DIGIT_SECOND_HALF_DELTA = 10


; Locations of the digits
DRAW_LEVEL_ROW      = 29
DRAW_LEVEL_COLUMN   = 23 

DRAW_SCORE_ROW      = 29
DRAW_SCORE_COLUMN   = 11
DRAW_HISCORE_COLUMN =  6

DRAW_STATS_ROW      =  8
DRAW_STATS_COLUMN   =  4
DRAW_STATS_SPACING  =  3
DRAW_N_STATS        =  7

DRAW_NEXT_ROW       = 25
DRAW_NEXT_COLUMN    = 15

DRAW_NLINES_ROW     = 20
DRAW_NLINES_COLUMN  =  1


;; VRAM Map
;; WORD ADDRESSES
GAME_MODE	= BGMODE_MODE7
GAME_MODE7	= 0
GAME_OAM_TILES	= $6000

GAME_OAM_SIZE	= OBSEL_SIZE_8_16
GAME_OAM_NAME	= 0

IMPORT_MODULE Ui
	;; Initialises the Ui Module
	;; Sets up the Screen Registers and loads tiles, maps and palette to PPU
	;; REQUIRES: 8 bit A, 16 bit Index
	;; MODIFIES: will force Blank
	ROUTINE Init

	;; Updates VRAM and PPU for the Mode7 Screen UI
	;; REQUIRES: 8 bit A, 16 bit Index
	ROUTINE VBlank

	;; Changes the location of the BG to match the
	;; game curret piece location
	;; REQUIRES: 8 bit A, 16 bit Index
	ROUTINE MoveGameField

	;; Rotates the screen counter clockwise 90 degrees.
	;; REQUIRES: 8 bit A, 16 bit Index
	ROUTINE RotateCc

	;; Rotates the screen clockwise 90 degrees.
	;; REQUIRES: 8 bit A, 16 bit Index
	ROUTINE RotateCw

	;; Checks to see if the current piece will collide
	;; with the current game map in its current position.
	;;
	;; REQUIRE: 8 bit A, 16 bit Index
	;; RETURN: c set if current piece is in the middle of the field.
	ROUTINE CheckPieceCollision

	;; Checks to see if the current piece will collide
	;; with the current game map if the piece moves to the left.
	;;
	;; REQUIRE: 8 bit A, 16 bit Index
	;; RETURN: c set if current piece cannot move to the left
	ROUTINE CheckPieceLeftCollision

	;; Checks to see if the current piece will collide
	;; with the current game map if the piece moves to the right.
	;;
	;; REQUIRE: 8 bit A, 16 bit Index
	;; RETURN: c set if current piece cannot move to the right
	ROUTINE CheckPieceRightCollision

	;; Checks to see if the current piece will collide
	;; with the current game map if the piece is rotated clockwise.
	;;
	;; REQUIRE: 8 bit A, 16 bit Index
	;; RETURN: c set if current piece cannot move to the right
	ROUTINE CheckPieceRotateCwCollision

	;; Checks to see if the current piece will collide
	;; with the current game map if the piece is rotated counter clockwise.
	;;
	;; REQUIRE: 8 bit A, 16 bit Index
	;; RETURN: c set if current piece cannot move to the right
	ROUTINE CheckPieceRotateCcCollision

	;; Checks to see if the current piece will collide
	;; with the current game map on the next drop.
	;;
	;; REQUIRE: 8 bit A, 16 bit Index
	;; RETURN: c set if current piece is on top of another.
	ROUTINE CheckPieceDropCollision

	;; Hghlights all of the tiles of a single line.
	;; Used for completed line animation.
	;; REQUIRES: 8 bit A, 16 bit Index
	;; INPUT: A = line
	ROUTINE HighlightLine

	;; Removes a single line from play by dropping all the previous
	;; lines on top of it.
	;; REQUIRES: 8 bit A, 16 bit Index
	;; INPUT: A = line
	ROUTINE RemoveLine

	;; Hides the current piece from the screen.
	;; REQUIRE: 8 bit A, 16 bit Index
	ROUTINE HideCurrentPiece

	;; Draws the current piece as a set of 4 sprites.
	;; REQUIRE: 8 bit A, 16 bit Index
	ROUTINE DrawCurrentPiece

	;; Draws the next piece in the next section
	;; REQUIRE: 8 bit A, 16 bit Index
	ROUTINE DrawNextPiece

	;; Draws the curren piece on the game field
	;; REQUIRE: 8 bit A, 16 bit Index
	ROUTINE	DrawCurrentPieceOnField

	;; Draws the number of lines to the screen
	;; REQUIRE: 8 bit A, 16 bit Index
	;; INPUT:
	;;	A - the level number
	ROUTINE DrawNLines

	;; Draws the level number to the screen
	;; REQUIRE: 8 bit A, 16 bit Index
	;; INPUT:
	;;	A - the level number
	ROUTINE DrawLevelNumber

	;; Draws the statsistics to the screen
	;; REQUIRE: 8 bit A, 16 bit Index
	ROUTINE DrawStatistics

	;; Draws the Hi Score to the screen
	;; REQUIRE: 8 bit A, 16 bit Index
	ROUTINE DrawHiScore

	;; Draws the Score to the screen
	ROUTINE DrawScore

ENDMODULE


.endif ; ::_UI_H_

; vim: set ft=asm:

