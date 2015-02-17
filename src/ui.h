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
SCREEN_HOFS	= SCREEN_CENTER_X - 256 / 2
SCREEN_VOFS	= SCREEN_CENTER_Y - 224 / 2

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

