
.include "resources.h"
.setcpu "65816"

.rodata
	; The game field is loaded in `ui.s`

	INCLUDE_BINARY gameFieldTiles,		"resources/mode7/game-field.pc7"
	INCLUDE_BINARY gameFieldPalette,	"resources/mode7/game-field.clr"

	INCLUDE_BINARY gameObjectsTiles,	"resources/tiles4bpp/game-objects.4bpp"
	INCLUDE_BINARY gameObjectsPalette,	"resources/tiles4bpp/game-objects.clr"


