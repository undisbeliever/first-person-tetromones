.ifndef ::_UI_H_
::_UI_H_ = 1

.setcpu "65816"

; Common includes
.include "includes/import_export.inc"
.include "includes/synthetic.inc"
.include "includes/registers.inc"
.include "includes/structure.inc"

.include "resources.h"

;; Game Center rotation point
SCREEN_CENTER_X	= 512
SCREEN_CENTER_Y	= 512

;; Top left position of the game field.
SCREEN_TOP_HOFS = 476 - 256 / 2
SCREEN_TOP_VOFS = 435 - 224 / 2

MODE7_TILE_WIDTH  = 128
MODE7_TILE_HEIGHT = 128

SCREEN_UI_COLUMN = 48
SCREEN_UI_ROW    = 50

SCREEN_TILE_HEIGHT = 28
SCREEN_TILE_WIDTH  = 32

NUMBER_DIGIT_DELTA = 6
NUMBER_DIGIT_SECOND_HALF_DELTA = 10

CURRENT_PIECE_XPOS = 128 - 32 / 2 + 4
CURRENT_PIECE_YPOS = 112 - 32 / 2 + 4 

DRAW_PIECE_ROW      = 10
DRAW_PIECE_COLUMN   = 3

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

	;; Draws the current piece as a set of 4 sprites.
	;; REQUIRE: 8 bit A, 16 bit Index
	ROUTINE DrawCurrentPiece

	;; Draws the next piece in the next section
	;; REQUIRE: 8 bit A, 16 bit Index
	ROUTINE DrawNextPiece
	
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

