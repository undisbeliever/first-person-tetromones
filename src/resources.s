
.include "resources.h"
.setcpu "65816"

.rodata
	; The game field is loaded in `ui.s`

	INCLUDE_BINARY gameFieldTiles,		"resources/game-field.pc7"
	INCLUDE_BINARY gameFieldPalette,	"resources/game-field.clr"

	INCLUDE_BINARY gameObjectsTiles,	"resources/game-objects.4bpp"
	INCLUDE_BINARY gameObjectsPalette,	"resources/game-objects.clr"


